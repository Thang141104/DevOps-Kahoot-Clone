# Production Code Standards Implementation Guide

## 🎯 Overview
This document explains the production-grade improvements implemented across all microservices.

## 📁 Shared Utilities Structure

```
services/shared/
├── config/
│   └── database.js          # MongoDB connection with pooling & retries
├── middleware/
│   ├── errorHandler.js      # Centralized error handling
│   ├── validator.js         # Input validation & sanitization
│   ├── security.js          # Rate limiting, CORS, Helmet
│   └── healthCheck.js       # Kubernetes health probes
└── utils/
    ├── logger.js            # Structured logging (Winston)
    └── serviceClient.js     # Circuit breaker & retry logic
```

## 🔒 Security Improvements

### 1. Rate Limiting
```javascript
// Protect against brute force attacks
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per IP
  message: 'Too many authentication attempts'
});
```

### 2. Input Validation
```javascript
// Prevent injection attacks
const validateRegistration = (req, res, next) => {
  // Email validation
  if (!isValidEmail(email)) {
    throw new ValidationError('Invalid email format');
  }
  
  // Strong password requirements
  if (!isStrongPassword(password)) {
    throw new ValidationError('Password too weak');
  }
  
  // Sanitize inputs
  req.body.username = sanitizeString(username);
  req.body.email = sanitizeString(email).toLowerCase();
};
```

### 3. Security Headers (Helmet)
- XSS Protection
- Content Security Policy
- HSTS (HTTP Strict Transport Security)
- No-Sniff headers
- Hide powered-by header

### 4. NoSQL Injection Prevention
```javascript
app.use(mongoSanitize()); // Removes $ and . from user input
```

## 📊 Logging & Monitoring

### 1. Structured Logging
```javascript
logger.info('User registered', {
  userId: user.id,
  email: user.email,
  timestamp: new Date().toISOString()
});

logger.error('Database connection failed', {
  error: err.message,
  stack: err.stack
});
```

### 2. HTTP Request Logging
```javascript
// Logs every HTTP request with duration
logger.http('HTTP Request', {
  method: 'POST',
  url: '/api/auth/login',
  status: 200,
  duration: '45ms',
  ip: '192.168.1.1'
});
```

### 3. Health Checks
```javascript
// Liveness probe (is service alive?)
GET /health/live => 200 OK

// Readiness probe (ready to accept traffic?)
GET /health/ready => 200 OK (with DB status)

// Detailed health check
GET /health => {
  status: 'UP',
  database: 'UP',
  memory: { heapUsed: '45 MB' },
  uptime: 3600
}
```

## 🔄 Resilience Patterns

### 1. Circuit Breaker
```javascript
// Prevents cascading failures
const circuitBreaker = new CircuitBreaker({
  failureThreshold: 5,      // Open after 5 failures
  resetTimeout: 60000       // Try again after 60s
});

// Auto-opens circuit after repeated failures
await circuitBreaker.execute(() => callExternalService());
```

### 2. Retry with Exponential Backoff
```javascript
// Automatically retry failed requests
await retryWithBackoff(async () => {
  return await externalService.call();
}, {
  maxRetries: 3,
  initialDelay: 1000,       // 1s, 2s, 4s
  backoffMultiplier: 2
});
```

### 3. Service Client
```javascript
// Resilient HTTP client for inter-service communication
const userClient = new ServiceClient('http://user-service:3002', {
  timeout: 5000,
  circuitBreaker: { failureThreshold: 5 },
  retry: { maxRetries: 3 }
});

// Automatically handles retries & circuit breaking
const user = await userClient.get('/api/users/123');
```

## 💾 Database Best Practices

### 1. Connection Pooling
```javascript
await mongoose.connect(uri, {
  maxPoolSize: 10,          // Max 10 concurrent connections
  minPoolSize: 2,           // Keep 2 always open
  socketTimeoutMS: 45000,   // Close inactive sockets
  retryWrites: true         // Auto-retry failed writes
});
```

### 2. Indexes for Performance
```javascript
// Create indexes for faster queries
await createIndexes(User, [
  { email: 1 },              // Unique email lookup
  { username: 1 },           // Unique username lookup
  { createdAt: -1 }          // Sort by date
]);
```

### 3. Transactions
```javascript
// Atomic operations across multiple collections
await withTransaction(async (session) => {
  await User.create([newUser], { session });
  await Profile.create([newProfile], { session });
  // Both succeed or both fail
});
```

## ⚡ Performance Optimizations

### 1. Request Size Limits
```javascript
app.use(express.json({ limit: '1mb' })); // Prevent large payloads
```

### 2. Response Compression
```javascript
const compression = require('compression');
app.use(compression()); // Gzip responses
```

### 3. Query Optimization
```javascript
// Use lean() for read-only queries (faster)
const users = await User.find().lean();

// Use select() to fetch only needed fields
const users = await User.find().select('name email');

// Use limit() and skip() for pagination
const users = await User.find()
  .limit(10)
  .skip(page * 10);
```

## 🧪 Code Quality

### 1. ESLint Configuration
- Prevent common errors (`no-undef`, `no-unused-vars`)
- Enforce best practices (`eqeqeq`, `no-eval`)
- Limit complexity (`max-lines-per-function: 50`)

### 2. Prettier Formatting
- Consistent code style
- Auto-formatting on save
- 100 character line width

### 3. Error Handling
```javascript
// Custom error classes
throw new ValidationError('Invalid input', errors);
throw new UnauthorizedError('Invalid credentials');
throw new NotFoundError('User');
throw new ConflictError('Email already exists');

// Async error wrapper (no try-catch needed)
router.post('/login', asyncHandler(async (req, res) => {
  const user = await User.findOne({ email });
  if (!user) {
    throw new UnauthorizedError('Invalid credentials');
  }
  res.json({ user });
}));
```

## 📝 Usage in Services

### Update Auth Service
```javascript
// Before
app.use(cors());
app.use(express.json());

// After
app.use(configureHelmet());
app.use(configureCors());
app.use(httpLogger);
app.use(express.json({ limit: '1mb' }));
app.use(sanitizeData());
app.use(preventPollution());
app.use('/api/auth/login', authLimiter);
```

### Update Routes
```javascript
// Before
router.post('/register', async (req, res) => {
  try {
    const user = await User.create(req.body);
    res.json({ user });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// After
router.post('/register', 
  validateRegistration,
  asyncHandler(async (req, res) => {
    const user = await User.create(req.body);
    logger.info('User registered', { userId: user.id });
    res.status(201).json({ 
      success: true, 
      user 
    });
  })
);
```

## 🚀 Deployment Steps

### 1. Install Dependencies
```bash
cd services/shared
npm install

cd ../auth-service
npm install winston express-rate-limit helmet express-mongo-sanitize hpp

cd ../user-service
npm install winston express-rate-limit helmet express-mongo-sanitize hpp
```

### 2. Update Each Service
- Copy shared utilities
- Update server.js to use production middlewares
- Update routes with validators and asyncHandler
- Add health check endpoints
- Update Dockerfile with shared dependencies

### 3. Testing
```bash
# Test health endpoints
curl http://localhost:3001/health/live
curl http://localhost:3001/health/ready

# Test rate limiting
for i in {1..10}; do curl http://localhost:3001/api/auth/login; done

# Test validation
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"invalid","password":"weak"}'
```

## 📈 Benefits

### Security
✅ Rate limiting prevents brute force attacks  
✅ Input validation prevents injection attacks  
✅ Security headers protect against XSS, clickjacking  
✅ CORS configured for production

### Reliability
✅ Circuit breaker prevents cascading failures  
✅ Retry logic handles transient errors  
✅ Connection pooling improves database performance  
✅ Graceful shutdown prevents data loss

### Observability
✅ Structured logging for debugging  
✅ Health checks for Kubernetes  
✅ Metrics for Prometheus  
✅ Request tracing for performance analysis

### Code Quality
✅ ESLint catches bugs early  
✅ Prettier ensures consistent style  
✅ Error handling is centralized  
✅ Async code is simplified

## 🎓 Best Practices Summary

1. **Always validate user input** - Use validators for all endpoints
2. **Use structured logging** - Makes debugging 10x easier
3. **Implement health checks** - Critical for Kubernetes deployments
4. **Rate limit sensitive endpoints** - Prevent abuse
5. **Use circuit breakers** - Prevent cascading failures
6. **Handle errors centrally** - Consistent error responses
7. **Log but don't expose** - Log errors, return generic messages
8. **Use connection pooling** - Improves database performance
9. **Implement graceful shutdown** - Prevents data corruption
10. **Monitor everything** - Metrics, logs, health checks

---

**Next Steps:**
1. ✅ Apply these patterns to all services
2. ⏭️ Add integration tests
3. ⏭️ Setup CI/CD quality gates
4. ⏭️ Configure production environment variables
5. ⏭️ Deploy to Kubernetes cluster
