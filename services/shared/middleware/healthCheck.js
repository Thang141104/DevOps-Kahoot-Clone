/**
 * Health Check Endpoints
 * Provides detailed health status for Kubernetes probes
 */

const mongoose = require('mongoose');
const { logger } = require('../utils/logger');

/**
 * Liveness probe - checks if the service is alive
 */
const livenessProbe = (req, res) => {
  res.status(200).json({
    status: 'UP',
    timestamp: new Date().toISOString(),
    service: process.env.SERVICE_NAME || 'unknown'
  });
};

/**
 * Readiness probe - checks if the service is ready to accept traffic
 */
const readinessProbe = async (req, res) => {
  try {
    const checks = {
      database: 'DOWN',
      memory: 'OK',
      uptime: process.uptime()
    };

    // Check database connection
    if (mongoose.connection.readyState === 1) {
      checks.database = 'UP';
    }

    // Check memory usage
    const memUsage = process.memoryUsage();
    const memUsageMB = {
      rss: Math.round(memUsage.rss / 1024 / 1024),
      heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024),
      heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024),
      external: Math.round(memUsage.external / 1024 / 1024)
    };

    // Warn if memory usage is high
    if (memUsageMB.heapUsed > 200) { // > 200MB
      checks.memory = 'WARNING';
      logger.warn('High memory usage detected', memUsageMB);
    }

    // Determine overall status
    const isHealthy = checks.database === 'UP';
    const statusCode = isHealthy ? 200 : 503;

    res.status(statusCode).json({
      status: isHealthy ? 'READY' : 'NOT_READY',
      timestamp: new Date().toISOString(),
      service: process.env.SERVICE_NAME || 'unknown',
      checks,
      memory: memUsageMB
    });
  } catch (error) {
    logger.error('Readiness probe failed:', error);
    res.status(503).json({
      status: 'NOT_READY',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
};

/**
 * Detailed health check with all dependencies
 */
const detailedHealthCheck = async (req, res) => {
  try {
    const health = {
      status: 'UP',
      timestamp: new Date().toISOString(),
      service: process.env.SERVICE_NAME || 'unknown',
      version: process.env.npm_package_version || '1.0.0',
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      checks: {}
    };

    // Database check
    health.checks.database = {
      status: mongoose.connection.readyState === 1 ? 'UP' : 'DOWN',
      readyState: mongoose.connection.readyState,
      host: mongoose.connection.host,
      name: mongoose.connection.name
    };

    // Memory check
    const memUsage = process.memoryUsage();
    health.checks.memory = {
      status: 'OK',
      rss: `${Math.round(memUsage.rss / 1024 / 1024)} MB`,
      heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)} MB`,
      heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)} MB`,
      external: `${Math.round(memUsage.external / 1024 / 1024)} MB`
    };

    // CPU check
    const cpuUsage = process.cpuUsage();
    health.checks.cpu = {
      user: `${Math.round(cpuUsage.user / 1000)} ms`,
      system: `${Math.round(cpuUsage.system / 1000)} ms`
    };

    // Determine overall status
    const allHealthy = Object.values(health.checks).every(
      check => check.status === 'UP' || check.status === 'OK'
    );
    health.status = allHealthy ? 'UP' : 'DEGRADED';

    res.status(allHealthy ? 200 : 503).json(health);
  } catch (error) {
    logger.error('Health check failed:', error);
    res.status(503).json({
      status: 'DOWN',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
};

module.exports = {
  livenessProbe,
  readinessProbe,
  detailedHealthCheck
};
