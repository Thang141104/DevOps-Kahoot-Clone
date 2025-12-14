const promClient = require('prom-client');

// Create a Registry to register the metrics
const register = new promClient.Registry();

// Add default metrics (CPU, Memory, Event Loop, GC, etc.)
promClient.collectDefaultMetrics({ 
  register,
  prefix: 'nodejs_',
  timeout: 10000
});

// ============================================
// HTTP REQUEST METRICS
// ============================================

// HTTP Request Duration Histogram
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code', 'service'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10] // Response time buckets
});

// HTTP Request Counter
const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code', 'service']
});

// HTTP Error Counter
const httpRequestErrors = new promClient.Counter({
  name: 'http_request_errors_total',
  help: 'Total number of HTTP request errors',
  labelNames: ['method', 'route', 'status_code', 'service', 'error_type']
});

// Active Connections Gauge
const activeConnections = new promClient.Gauge({
  name: 'http_active_connections',
  help: 'Number of active HTTP connections',
  labelNames: ['service']
});

// Register HTTP metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(httpRequestErrors);
register.registerMetric(activeConnections);

// ============================================
// BUSINESS METRICS (Optional - Customize per service)
// ============================================

// Active Users
const activeUsers = new promClient.Gauge({
  name: 'kahoot_active_users',
  help: 'Number of currently active users'
});

// Login Attempts
const loginAttempts = new promClient.Counter({
  name: 'kahoot_login_attempts_total',
  help: 'Total login attempts',
  labelNames: ['status'] // success, failed
});

// Games Metrics
const gamesCreated = new promClient.Counter({
  name: 'kahoot_games_created_total',
  help: 'Total number of games created'
});

const activeGames = new promClient.Gauge({
  name: 'kahoot_active_games',
  help: 'Number of currently active games'
});

const gamePlayers = new promClient.Histogram({
  name: 'kahoot_game_players',
  help: 'Number of players per game',
  buckets: [1, 5, 10, 20, 50, 100]
});

// Quiz Metrics
const quizzesCreated = new promClient.Counter({
  name: 'kahoot_quizzes_created_total',
  help: 'Total number of quizzes created'
});

// WebSocket Metrics
const websocketConnections = new promClient.Gauge({
  name: 'websocket_connections',
  help: 'Number of active WebSocket connections',
  labelNames: ['service']
});

// Register business metrics (optional)
register.registerMetric(activeUsers);
register.registerMetric(loginAttempts);
register.registerMetric(gamesCreated);
register.registerMetric(activeGames);
register.registerMetric(gamePlayers);
register.registerMetric(quizzesCreated);
register.registerMetric(websocketConnections);

// ============================================
// MIDDLEWARE FUNCTION
// ============================================

function metricsMiddleware(serviceName) {
  return (req, res, next) => {
    // Skip /metrics endpoint itself
    if (req.path === '/metrics') {
      return next();
    }

    const start = Date.now();
    
    // Increment active connections
    activeConnections.inc({ service: serviceName });
    
    // Override res.end to capture metrics
    const originalEnd = res.end;
    res.end = function(...args) {
      const duration = (Date.now() - start) / 1000; // Convert to seconds
      const route = req.route ? req.route.path : req.path;
      const labels = {
        method: req.method,
        route: route,
        status_code: res.statusCode,
        service: serviceName
      };
      
      // Record metrics
      httpRequestDuration.observe(labels, duration);
      httpRequestTotal.inc(labels);
      
      // Track errors
      if (res.statusCode >= 400) {
        const errorType = res.statusCode >= 500 ? 'server_error' : 'client_error';
        httpRequestErrors.inc({
          ...labels,
          error_type: errorType
        });
      }
      
      // Decrement active connections
      activeConnections.dec({ service: serviceName });
      
      originalEnd.apply(res, args);
    };
    
    next();
  };
}

// ============================================
// EXPORTS
// ============================================

module.exports = {
  // Middleware
  metricsMiddleware,
  
  // Registry (for /metrics endpoint)
  register,
  
  // Business metrics for manual tracking
  metrics: {
    activeUsers,
    loginAttempts,
    gamesCreated,
    activeGames,
    gamePlayers,
    quizzesCreated,
    websocketConnections
  }
};
