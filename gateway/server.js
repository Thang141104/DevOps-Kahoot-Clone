const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
// DO NOT parse body in gateway - let target services handle it
// app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Proxy configurations
const services = {
  auth: {
    target: process.env.AUTH_SERVICE_URL || 'http://localhost:3001',
    pathRewrite: { '^/api/auth': '' }
  },
  quiz: {
    target: process.env.QUIZ_SERVICE_URL || 'http://localhost:3002',
    pathRewrite: { '^/api/quiz': '' }
  },
  game: {
    target: process.env.GAME_SERVICE_URL || 'http://localhost:3003',
    pathRewrite: { '^/api/game': '' }
  },
  user: {
    target: process.env.USER_SERVICE_URL || 'http://localhost:3004',
    pathRewrite: { '^/api/user': '' }
  },
  analytics: {
    target: process.env.ANALYTICS_SERVICE_URL || 'http://localhost:3005',
    pathRewrite: { '^/api/analytics': '' }
  }
};

// Setup proxies
Object.keys(services).forEach(service => {
  app.use(
    `/api/${service}`,
    createProxyMiddleware({
      target: services[service].target,
      changeOrigin: true,
      pathRewrite: services[service].pathRewrite,
      onError: (err, req, res) => {
        console.error(`Proxy error for ${service}:`, err);
        res.status(503).json({
          error: 'Service Unavailable',
          message: `${service} service is currently unavailable`
        });
      }
    })
  );
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

const PORT = process.env.PORT || 3000;  // Keep at 3000 for gateway
app.listen(PORT, () => {
  console.log(`🚀 API Gateway running on port ${PORT}`);
  console.log(`📍 Environment: ${process.env.NODE_ENV}`);
});
