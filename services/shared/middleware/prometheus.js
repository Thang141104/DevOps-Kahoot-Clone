/**
 * Prometheus Metrics Middleware
 * Adds Prometheus metrics to Express apps
 */

const client = require('prom-client');

// Create a Registry
const register = new client.Registry();

// Add default metrics (CPU, memory, etc.)
client.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code', 'service']
});

const httpErrorsTotal = new client.Counter({
  name: 'http_errors_total',
  help: 'Total number of HTTP errors',
  labelNames: ['method', 'route', 'status_code', 'service']
});

const activeUsers = new client.Gauge({
  name: 'active_users_total',
  help: 'Number of active users',
  labelNames: ['service']
});

const databaseConnections = new client.Gauge({
  name: 'database_connections',
  help: 'Number of active database connections',
  labelNames: ['status']
});

// Register metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);
register.registerMetric(httpErrorsTotal);
register.registerMetric(activeUsers);
register.registerMetric(databaseConnections);

/**
 * Prometheus middleware for Express
 */
function prometheusMiddleware(serviceName) {
  return (req, res, next) => {
    const start = Date.now();

    // Track request completion
    res.on('finish', () => {
      const duration = (Date.now() - start) / 1000;
      const route = req.route ? req.route.path : req.path;
      const statusCode = res.statusCode.toString();

      // Record metrics
      httpRequestDuration.labels(req.method, route, statusCode).observe(duration);
      httpRequestsTotal.labels(req.method, route, statusCode, serviceName).inc();

      // Track errors (4xx, 5xx)
      if (res.statusCode >= 400) {
        httpErrorsTotal.labels(req.method, route, statusCode, serviceName).inc();
      }
    });

    next();
  };
}

/**
 * Metrics endpoint handler
 */
async function metricsHandler(req, res) {
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
  } catch (err) {
    res.status(500).end(err);
  }
}

// Export metrics and middleware
module.exports = {
  prometheusMiddleware,
  metricsHandler,
  register,
  metrics: {
    httpRequestDuration,
    httpRequestsTotal,
    httpErrorsTotal,
    activeUsers,
    databaseConnections
  }
};
