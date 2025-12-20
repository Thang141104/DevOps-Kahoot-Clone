# Application Metrics Implementation

Quick guide để implement Prometheus metrics cho từng service.

## 📋 Checklist

### Gateway Service
- [ ] Install prom-client
- [ ] Copy metrics.js
- [ ] Update server.js
- [ ] Add /metrics endpoint
- [ ] Update deployment YAML annotations
- [ ] Test metrics endpoint

### Auth Service  
- [ ] Install prom-client
- [ ] Copy metrics.js
- [ ] Update server.js
- [ ] Track login attempts
- [ ] Add /metrics endpoint
- [ ] Update deployment YAML annotations

### Quiz Service
- [ ] Install prom-client
- [ ] Copy metrics.js
- [ ] Update server.js
- [ ] Track quiz creation
- [ ] Add /metrics endpoint
- [ ] Update deployment YAML annotations

### Game Service
- [ ] Install prom-client
- [ ] Copy metrics.js
- [ ] Update server.js
- [ ] Track active games & players
- [ ] Track WebSocket connections
- [ ] Add /metrics endpoint
- [ ] Update deployment YAML annotations

### User Service
- [ ] Install prom-client
- [ ] Copy metrics.js
- [ ] Update server.js
- [ ] Track active users
- [ ] Add /metrics endpoint
- [ ] Update deployment YAML annotations

### Analytics Service
- [ ] Install prom-client
- [ ] Copy metrics.js
- [ ] Update server.js
- [ ] Add /metrics endpoint
- [ ] Update deployment YAML annotations

## 🚀 Quick Implementation (Per Service)

### 1. Install Dependencies

```bash
cd services/<service-name>
npm install prom-client --save
```

### 2. Create metrics.js

Copy content from `METRICS_TEMPLATE.js` to `services/<service-name>/middleware/metrics.js`

### 3. Update server.js

```javascript
// At the top
const { metricsMiddleware, register } = require('./middleware/metrics');

// After express() init, BEFORE other middleware
app.use(metricsMiddleware('service-name')); // Replace with actual service name

// Add metrics endpoint (near other routes)
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
  } catch (err) {
    console.error('Error generating metrics:', err);
    res.status(500).end(err.message);
  }
});
```

### 4. Track Business Metrics (Optional)

Example for auth-service:

```javascript
const { metrics } = require('./middleware/metrics');

// In login route
router.post('/login', async (req, res) => {
  try {
    // ... your login logic ...
    metrics.loginAttempts.inc({ status: 'success' });
    res.json({ success: true, token });
  } catch (error) {
    metrics.loginAttempts.inc({ status: 'failed' });
    res.status(401).json({ error: 'Login failed' });
  }
});
```

Example for game-service:

```javascript
const { metrics } = require('./middleware/metrics');

// Track active games
io.on('connection', (socket) => {
  metrics.websocketConnections.inc({ service: 'game' });
  
  socket.on('create-game', (data) => {
    metrics.gamesCreated.inc();
    metrics.activeGames.inc();
  });
  
  socket.on('game-end', (data) => {
    metrics.activeGames.dec();
    metrics.gamePlayers.observe(data.playerCount);
  });
  
  socket.on('disconnect', () => {
    metrics.websocketConnections.dec({ service: 'game' });
  });
});
```

### 5. Update Deployment YAML

Add annotations to `k8s/<service>-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <service-name>
  namespace: kahoot-clone
spec:
  template:
    metadata:
      labels:
        app: <service-name>
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "<port>"  # e.g., 3000, 3001, 3002
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: <service-name>
        # ... rest of config ...
```

### 6. Test Locally

```bash
# Start service
npm start

# Test metrics endpoint
curl http://localhost:<port>/metrics

# Should see output like:
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
# http_requests_total{method="GET",route="/",status_code="200",service="gateway"} 1
```

### 7. Commit and Deploy

```bash
git add .
git commit -m "feat: Add Prometheus metrics to <service-name>"
git push
```

## 🔍 Verification

After deployment, verify metrics are being scraped:

```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Visit http://localhost:9090/targets
# Should see all your services as UP
```

## 📊 Available Metrics

### Default Node.js Metrics
- `nodejs_heap_size_total_bytes` - Heap size
- `nodejs_heap_size_used_bytes` - Used heap
- `nodejs_external_memory_bytes` - External memory
- `nodejs_eventloop_lag_seconds` - Event loop lag
- `process_cpu_user_seconds_total` - CPU usage
- `process_resident_memory_bytes` - Memory usage

### HTTP Metrics
- `http_requests_total` - Total requests
- `http_request_duration_seconds` - Request duration
- `http_request_errors_total` - Error count
- `http_active_connections` - Active connections

### Business Metrics
- `kahoot_active_users` - Current active users
- `kahoot_login_attempts_total` - Login attempts
- `kahoot_games_created_total` - Games created
- `kahoot_active_games` - Current active games
- `kahoot_game_players` - Players per game
- `kahoot_quizzes_created_total` - Quizzes created
- `websocket_connections` - WebSocket connections

## 🎯 Prometheus Query Examples

```promql
# Request rate by service
rate(http_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Error rate
rate(http_request_errors_total[5m])

# Active users
kahoot_active_users

# Games created per hour
increase(kahoot_games_created_total[1h])
```

## ✅ Done!

Your services now expose Prometheus metrics and will be automatically scraped every 15 seconds.
