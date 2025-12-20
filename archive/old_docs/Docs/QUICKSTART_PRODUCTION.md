# Quick Start: Apply Production Standards

## 🚀 5 Phút Để Production-Ready

### Bước 1: Review Changes (1 phút)

```powershell
# Xem các files mới được tạo
Get-ChildItem -Recurse -Include "*production*","*.eslintrc.js",".prettierrc.js" | Select-Object FullName
```

**Files đã được tạo**:
- ✅ `services/shared/` - Production utilities
- ✅ `.eslintrc.js` - Linting rules
- ✅ `.prettierrc.js` - Code formatting
- ✅ `jest.config.js` - Test configuration
- ✅ `migrate-to-production.ps1` - Migration script
- ✅ Production documentation files

### Bước 2: Run Migration Script (2 phút)

```powershell
# Di chuyển đến root directory
cd D:\DevOps_Lab2\DevOps-Kahoot-Clone

# Run migration script
.\migrate-to-production.ps1

# Output sẽ hiển thị:
# ✓ Shared dependencies installed
# ✓ Updated auth-service
# ✓ Updated user-service
# ✓ ...
# ✅ Production Migration Complete!
```

**Script sẽ làm gì?**
1. Install shared production dependencies
2. Backup original files (server.js → server.js.backup)
3. Apply production code to all services
4. Setup ESLint & Prettier
5. Configure pre-commit hooks

### Bước 3: Test Locally (2 phút)

```powershell
# Build với production code
docker-compose build

# Start services
docker-compose up -d

# Wait 30 seconds cho services khởi động
Start-Sleep -Seconds 30

# Check health endpoints
curl http://localhost:3001/health  # Auth Service
curl http://localhost:3002/health  # User Service
curl http://localhost:3003/health  # Quiz Service
curl http://localhost:3004/health  # Game Service
curl http://localhost:3005/health  # Analytics Service

# Check logs (structured Winston logs)
docker-compose logs auth-service | Select-Object -Last 20
```

**Expected output**:
```json
{
  "status": "UP",
  "timestamp": "2025-12-17T10:30:00.000Z",
  "service": "auth-service",
  "checks": {
    "database": { "status": "UP" },
    "memory": { "heapUsed": "45 MB" }
  }
}
```

### Bonus: Run Quality Checks (optional)

```powershell
# Lint code
npm run lint

# Check formatting
npm run format:check

# Run tests
npm test

# Security audit
npm audit
```

---

## 🎯 Nếu Muốn Manual Review Từng Service

### Auth Service Example

```powershell
cd services\auth-service

# Compare files
code -d server.js server-production.js
code -d Dockerfile Dockerfile.production

# Review changes:
# - ✅ Winston logging
# - ✅ Error handling
# - ✅ Rate limiting
# - ✅ Input validation
# - ✅ Health checks
# - ✅ Circuit breaker

# Test build
docker build -f Dockerfile.production -t test-auth .

# Test run
docker run -p 3001:3001 test-auth
```

---

## 📝 Apply Production Code (Manual)

Nếu không dùng migration script, có thể apply manual:

### 1. Auth Service
```powershell
cd services\auth-service

# Backup
Copy-Item server.js server.js.backup
Copy-Item Dockerfile Dockerfile.backup

# Apply production code
Copy-Item server-production.js server.js -Force
Copy-Item Dockerfile.production Dockerfile -Force

# Install dependencies
npm install winston express-rate-limit helmet express-mongo-sanitize hpp
```

### 2. Shared Utilities
```powershell
cd ..\shared

# Install
npm install
```

### 3. Repeat cho các services khác
```powershell
# User Service
cd ..\user-service
npm install winston express-rate-limit helmet express-mongo-sanitize hpp

# Quiz Service
cd ..\quiz-service
npm install winston express-rate-limit helmet express-mongo-sanitize hpp

# Tương tự cho game-service và analytics-service
```

---

## 🔥 Fast Track: Deploy Ngay

```powershell
# 1. Run migration
.\migrate-to-production.ps1

# 2. Test local
docker-compose up -d
curl http://localhost:3001/health

# 3. Commit changes
git add .
git commit -m "feat: production code standards - security, logging, resilience"
git push origin fix/auth-routing-issues

# 4. Update Jenkinsfile
Copy-Item Jenkinsfile.production Jenkinsfile -Force
git add Jenkinsfile
git commit -m "feat: CI/CD with quality gates"
git push

# 5. Trigger Jenkins build
# Jenkins pipeline sẽ:
# - Run ESLint
# - Run tests
# - Security scan
# - Build images
# - Deploy to K8s
# - Health check
```

---

## ✅ Verification Checklist

Sau khi migration, verify:

### Security
```powershell
# Test rate limiting
for ($i=1; $i -le 10; $i++) {
  curl http://localhost:3001/api/auth/login -Method POST
}
# Should see "Too many requests" after 5 attempts

# Test validation
curl http://localhost:3001/api/auth/register -Method POST -Body '{"email":"invalid","password":"weak"}' -ContentType "application/json"
# Should see validation errors
```

### Logging
```powershell
# Check structured logs
docker-compose logs auth-service | Select-String "HTTP Request"

# Should see:
# [INFO] HTTP Request { method: 'POST', url: '/api/auth/login', status: 200, duration: '45ms' }
```

### Health Checks
```powershell
# Liveness
curl http://localhost:3001/health/live
# { "status": "UP" }

# Readiness
curl http://localhost:3001/health/ready
# { "status": "READY", "database": "UP" }

# Detailed
curl http://localhost:3001/health
# { "status": "UP", "checks": { ... } }
```

### Circuit Breaker
```powershell
# Stop user service
docker-compose stop user-service

# Try to call from game service (should fail fast)
# Circuit opens after 5 failures
# Won't try again for 60 seconds
```

---

## 🎓 Understanding the Improvements

### Before (Old Code)
```javascript
// server.js (old)
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'OK' });
});

app.post('/api/auth/register', async (req, res) => {
  try {
    const user = await User.create(req.body);
    res.json({ user });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

**Problems**:
❌ No rate limiting (DDoS vulnerable)  
❌ No input validation (injection attacks)  
❌ No security headers (XSS vulnerable)  
❌ No logging (hard to debug)  
❌ No health checks (K8s can't monitor)  
❌ No error handling (inconsistent responses)  

### After (Production Code)
```javascript
// server.js (production)
const { logger, httpLogger } = require('../shared/utils/logger');
const { errorHandler, asyncHandler } = require('../shared/middleware/errorHandler');
const { configureCors, configureHelmet, authLimiter } = require('../shared/middleware/security');
const { validateRegistration } = require('../shared/middleware/validator');
const { livenessProbe, readinessProbe } = require('../shared/middleware/healthCheck');

app.use(configureHelmet());        // Security headers
app.use(configureCors());          // CORS whitelist
app.use(httpLogger);               // Request logging
app.use(express.json({ limit: '1mb' })); // Size limit
app.use(sanitizeData());           // NoSQL injection prevention

app.get('/health/live', livenessProbe);
app.get('/health/ready', readinessProbe);

app.use('/api/auth/register', authLimiter); // Rate limiting

app.post('/api/auth/register', 
  validateRegistration,            // Input validation
  asyncHandler(async (req, res) => {
    const user = await User.create(req.body);
    logger.info('User registered', { userId: user.id });
    res.status(201).json({ success: true, user });
  })
);

app.use(errorHandler);             // Centralized error handling
```

**Benefits**:
✅ Rate limiting (5 attempts/15min)  
✅ Input validation (email, password strength)  
✅ Security headers (XSS, clickjacking protection)  
✅ Structured logging (Winston)  
✅ Health checks (K8s probes)  
✅ Error handling (consistent responses)  

---

## 🚨 Troubleshooting

### Issue: Migration script fails
```powershell
# Check PowerShell execution policy
Get-ExecutionPolicy

# If Restricted, set to RemoteSigned
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run script again
.\migrate-to-production.ps1
```

### Issue: Docker build fails
```powershell
# Check Dockerfile path
Get-ChildItem services\auth-service\Dockerfile*

# Build with verbose output
docker build -f services\auth-service\Dockerfile.production --progress=plain .
```

### Issue: Health check returns 503
```powershell
# Check MongoDB connection
docker-compose logs mongodb

# Check service logs
docker-compose logs auth-service | Select-String "MongoDB"

# Verify MONGODB_URI in .env or docker-compose.yml
```

### Issue: Rate limiting not working
```powershell
# Verify authLimiter is applied
docker-compose logs auth-service | Select-String "authLimiter"

# Check if running production code
docker-compose exec auth-service cat server.js | Select-String "authLimiter"
```

---

## 📞 Support

Nếu gặp vấn đề:
1. Check [PRODUCTION_CODE_STANDARDS.md](PRODUCTION_CODE_STANDARDS.md) - Detailed documentation
2. Review [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md) - Quality checklist
3. Check logs: `docker-compose logs -f [service-name]`
4. Verify health: `curl http://localhost:300X/health`

---

## ✨ Summary

**3 commands để production-ready**:
```powershell
.\migrate-to-production.ps1  # Apply production code
docker-compose up -d         # Test locally
git add . && git commit && git push  # Deploy
```

**Kết quả**:
✅ Security hardened (rate limit, validation, Helmet)  
✅ Logging structured (Winston)  
✅ Resilience patterns (circuit breaker, retry)  
✅ Health checks (K8s ready)  
✅ Code quality (ESLint, Prettier)  
✅ CI/CD quality gates (tests, security scan)  

🚀 **Production ready in 5 minutes!**
