require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const { metricsMiddleware, register } = require('./utils/metrics');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3005;

// Metrics middleware
app.use(metricsMiddleware);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Import routes
const eventsRoutes = require('./routes/events.routes');
const statsRoutes = require('./routes/stats.routes');

// MongoDB connection
mongoose.connect(process.env.MONGODB_URI)
.then(() => {
  console.log('✅ Connected to MongoDB (Analytics Service)');
})
.catch((error) => {
  console.error('❌ MongoDB connection error:', error);
  process.exit(1);
});

// Routes
app.use('/events', eventsRoutes);
app.use('/stats', statsRoutes);
app.use('/reports', statsRoutes); // Reports are also in stats routes

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
  } catch (err) {
    res.status(500).end(err.message);
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    service: 'Analytics Service',
    status: 'healthy',
    timestamp: new Date(),
    uptime: process.uptime()
  });
});

// Root route
app.get('/', (req, res) => {
  res.json({
    service: 'Analytics Service',
    version: '1.0.0',
    endpoints: {
      events: {
        'POST /events': 'Track a new event',
        'GET /events/type/:eventType': 'Get events by type',
        'GET /events/user/:userId': 'Get events by user',
        'GET /events/range': 'Get events by date range',
        'GET /events/count/:eventType': 'Get event count',
        'GET /events/aggregated': 'Get aggregated events',
        'GET /popular/quizzes': 'Get popular quizzes',
        'GET /users/active': 'Get active users count'
      },
      stats: {
        'GET /stats/global': 'Get global statistics',
        'GET /stats/dashboard': 'Get dashboard summary',
        'GET /stats/user/:userId/engagement': 'Get user engagement metrics',
        'GET /stats/trends': 'Get platform trends'
      }
    }
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Server error:', error);
  res.status(500).json({
    error: 'Internal server error',
    message: error.message
  });
});

// Start server - bind to 0.0.0.0 for container access
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Analytics Service running on 0.0.0.0:${PORT}`);
  console.log(`📊 Event tracking enabled`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received, shutting down gracefully...');
  mongoose.connection.close(false, () => {
    console.log('💤 MongoDB connection closed');
    process.exit(0);
  });
});
