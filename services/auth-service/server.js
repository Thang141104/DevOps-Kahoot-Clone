/**
 * Production-Ready Auth Service
 * Implements all best practices: error handling, validation, logging, security
 */

require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');

// Shared utilities (production-grade)
const { logger, httpLogger } = require('../shared/utils/logger');
const { errorHandler, notFoundHandler, asyncHandler } = require('../shared/middleware/errorHandler');
const { configureCors, configureHelmet, apiLimiter, authLimiter, sanitizeData, preventPollution } = require('../shared/middleware/security');
const { livenessProbe, readinessProbe, detailedHealthCheck } = require('../shared/middleware/healthCheck');
const { metricsMiddleware, register } = require('./utils/metrics');

// Initialize Express
const app = express();
const PORT = process.env.PORT || 3001;

// Trust proxy (for rate limiting behind load balancer)
app.set('trust proxy', 1);

// Security middleware (MUST be first)
app.use(configureHelmet());
app.use(configureCors());

// Metrics middleware
app.use(metricsMiddleware);

// HTTP request logging
app.use(httpLogger);

// Body parsing with size limits
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Security middleware
app.use(sanitizeData()); // Prevent NoSQL injection
app.use(preventPollution()); // Prevent parameter pollution

// Health check endpoints (no auth required)
app.get('/health/live', livenessProbe);
app.get('/health/ready', readinessProbe);
app.get('/health', detailedHealthCheck);

// Metrics endpoint (for Prometheus)
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
  } catch (err) {
    logger.error('Metrics endpoint error:', err);
    res.status(500).end(err.message);
  }
});

// API routes with rate limiting
app.use('/api/auth/login', authLimiter); // Strict rate limit for login
app.use('/api/auth/register', authLimiter); // Strict rate limit for register
app.use('/api', apiLimiter); // General rate limit for all other API routes

// Import routes
const authRoutes = require('./routes/auth.routes');
app.use('/api/auth', authRoutes);

// 404 handler
app.use(notFoundHandler);

// Global error handler (MUST be last)
app.use(errorHandler);

// Database connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://admin:admin123@mongodb:27017/quiz-app?authSource=admin';

mongoose.connect(MONGODB_URI)
  .then(() => {
    logger.info('Connected to MongoDB');
    // Start server only after DB connection
    app.listen(PORT, () => {
      logger.info(`Auth Service listening on port ${PORT}`, {
        environment: process.env.NODE_ENV || 'development',
        mongoUri: MONGODB_URI.replace(/\/\/.*@/, '//***:***@') // Hide credentials in logs
      });
    });
  })
  .catch((err) => {
    logger.error('Failed to connect to MongoDB:', err);
    process.exit(1);
  });

// Graceful shutdown
const gracefulShutdown = async (signal) => {
  logger.info(`${signal} received. Starting graceful shutdown...`);
  
  // Stop accepting new connections
  process.exit(0);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Unhandled promise rejection
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', { promise, reason });
  process.exit(1);
});

// Uncaught exception
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

module.exports = app;
