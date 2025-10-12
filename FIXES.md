# Auth Service - Issues & Fixes

## Issues Found

### Issue #1: API Routing - Double `/auth` Prefix
**Problem:** Frontend called `/api/auth/auth/register` causing 404 errors.

**Root Cause:**
- Frontend: `fetch('/api/auth/auth/register')` ❌
- Gateway: strips `/api/auth` → forwards `/auth/register`
- Auth Service: routes at `/auth/*` → final path becomes `/auth/auth/register`

**Fix:**
1. Auth Service: Change `app.use('/auth', routes)` → `app.use('/', routes)`
2. Frontend: Change all URLs from `/api/auth/auth/*` → `/api/auth/*`

### Issue #2: Request Body Consumed by Gateway
**Problem:** "BadRequestError: request aborted" in auth-service.

**Root Cause:**
Gateway had `app.use(express.json())` which consumed the request body before proxying.

**Fix:**
Remove `app.use(express.json())` from gateway/server.js. Gateway should only proxy, not parse.

---

## Code Changes

### 1. Gateway (`gateway/server.js`)
```javascript
// Remove this line:
// app.use(express.json());

// Gateway should NOT parse body - let target services handle it
```

### 2. Auth Service (`services/auth-service/server.js`)
```javascript
// Before
app.use('/auth', require('./routes/auth.routes'));

// After
app.get('/health', ...); // Health check first
app.use('/', require('./routes/auth.routes')); // No prefix
```

### 3. Frontend API Calls
**Files:** `Register.js`, `Login.js`, `VerifyOTP.js`

```javascript
// Before
fetch('http://localhost:3000/api/auth/auth/register', ...)
fetch('http://localhost:3000/api/auth/auth/login', ...)
fetch('http://localhost:3000/api/auth/auth/verify-otp', ...)

// After
fetch('http://localhost:3000/api/auth/register', ...)
fetch('http://localhost:3000/api/auth/login', ...)
fetch('http://localhost:3000/api/auth/verify-otp', ...)
```

---

## Correct API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/register` | POST | User registration |
| `/api/auth/login` | POST | User login |
| `/api/auth/verify-otp` | POST | Verify OTP code |
| `/api/auth/resend-otp` | POST | Resend OTP |
| `/api/auth/me` | GET | Get current user |

---

## Testing

```powershell
# Test endpoints
node test-api.js

# Expected: All health checks pass, register endpoint reachable
```

---

## Key Takeaways

1. **API Gateway Pattern**: Never parse body in gateway when proxying
2. **Microservice Routing**: When gateway strips prefix, service routes should be at root level
3. **Endpoint Consistency**: Use single `/api/auth/*` not double `/api/auth/auth/*`
