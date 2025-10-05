# API Testing Guide

## Test Auth Service với Postman/cURL

### 1. Health Check
```bash
GET http://localhost:3001/health
```

### 2. Register User
```bash
POST http://localhost:3000/api/auth/auth/register
Content-Type: application/json

{
  "username": "testuser",
  "email": "test@example.com",
  "password": "password123"
}

Response:
{
  "success": true,
  "message": "Registration successful! Please check your email for OTP verification code.",
  "userId": "507f1f77bcf86cd799439011"
}
```

### 3. Verify OTP
```bash
POST http://localhost:3000/api/auth/auth/verify-otp
Content-Type: application/json

{
  "userId": "507f1f77bcf86cd799439011",
  "otp": "123456"
}

Response:
{
  "success": true,
  "message": "Email verified successfully!",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "username": "testuser",
    "email": "test@example.com",
    "role": "user"
  }
}
```

### 4. Resend OTP
```bash
POST http://localhost:3000/api/auth/auth/resend-otp
Content-Type: application/json

{
  "userId": "507f1f77bcf86cd799439011"
}

Response:
{
  "success": true,
  "message": "OTP resent successfully! Please check your email."
}
```

### 5. Login
```bash
POST http://localhost:3000/api/auth/auth/login
Content-Type: application/json

{
  "emailOrUsername": "testuser",
  "password": "password123"
}

Response:
{
  "success": true,
  "message": "Login successful!",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "username": "testuser",
    "email": "test@example.com",
    "role": "user"
  }
}
```

### 6. Get Current User (Protected)
```bash
GET http://localhost:3000/api/auth/auth/me
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

Response:
{
  "success": true,
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "username": "testuser",
    "email": "test@example.com",
    "role": "user",
    "isVerified": true,
    "createdAt": "2025-10-04T07:00:00.000Z"
  }
}
```

## PowerShell Testing Scripts

### Quick Test Register
```powershell
$body = @{
    username = "testuser"
    email = "test@example.com"
    password = "password123"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/auth/auth/register" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body
```

### Quick Test Login
```powershell
$body = @{
    emailOrUsername = "testuser"
    password = "password123"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/auth/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body

$token = $response.token
Write-Host "Token: $token"
```

### Test with Token
```powershell
$headers = @{
    "Authorization" = "Bearer $token"
}

Invoke-RestMethod -Uri "http://localhost:3000/api/auth/auth/me" `
    -Method GET `
    -Headers $headers
```

## Common Test Scenarios

### Test 1: Complete Registration Flow
1. Register new user
2. Check email for OTP (or console log)
3. Verify OTP
4. Receive JWT token
5. Access protected routes

### Test 2: Login Flow
1. Login with credentials
2. Receive JWT token
3. Store token
4. Make authenticated requests

### Test 3: Error Handling
1. Register with existing email → 400 Error
2. Login with wrong password → 401 Error
3. Verify with wrong OTP → 400 Error
4. Verify expired OTP → 400 Error
5. Access protected route without token → 401 Error

### Test 4: OTP Expiration
1. Register user
2. Wait 10+ minutes
3. Try to verify OTP → Should fail
4. Resend OTP
5. Verify with new OTP → Should succeed

## MongoDB Queries for Testing

### Check all users
```javascript
use quiz-app
db.users.find().pretty()
```

### Check specific user
```javascript
db.users.findOne({ email: "test@example.com" })
```

### Delete test user
```javascript
db.users.deleteOne({ email: "test@example.com" })
```

### Check verified users
```javascript
db.users.find({ isVerified: true }).pretty()
```

### Check users with pending OTP
```javascript
db.users.find({ 
  isVerified: false, 
  "otp.code": { $exists: true } 
}).pretty()
```

## Frontend Testing Checklist

### Register Page
- [ ] Form validation works
- [ ] Username min 3 chars enforced
- [ ] Password min 6 chars enforced
- [ ] Passwords match validation
- [ ] Email format validation
- [ ] Loading state shows
- [ ] Error messages display
- [ ] Success redirect to OTP page

### OTP Page
- [ ] 6 input boxes display
- [ ] Auto-focus next input
- [ ] Backspace works correctly
- [ ] Paste OTP works
- [ ] Auto-submit when complete
- [ ] Timer countdown works
- [ ] Resend button appears after 60s
- [ ] Resend functionality works
- [ ] Success redirect to dashboard

### Login Page
- [ ] Login with username works
- [ ] Login with email works
- [ ] Wrong password shows error
- [ ] Unverified user redirects to OTP
- [ ] Success redirect to dashboard
- [ ] Token saved to localStorage
- [ ] User info saved to localStorage

### Home Page
- [ ] Create Quiz button checks auth
- [ ] Logged in → Dashboard
- [ ] Not logged in → Login page
- [ ] Join Quiz works without auth

## Performance Testing

### Load Test Registration
```powershell
# Test 10 concurrent registrations
1..10 | ForEach-Object -Parallel {
    $body = @{
        username = "user$_"
        email = "user$_@example.com"
        password = "password123"
    } | ConvertTo-Json

    Invoke-RestMethod -Uri "http://localhost:3000/api/auth/auth/register" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body
}
```

### Monitor Response Times
Check API Gateway logs and Auth Service logs for performance metrics.

## Security Testing

### Test 1: SQL Injection (Should be protected by MongoDB)
```json
{
  "emailOrUsername": "admin' OR '1'='1",
  "password": "anything"
}
```

### Test 2: XSS (Should be sanitized)
```json
{
  "username": "<script>alert('XSS')</script>",
  "email": "test@example.com",
  "password": "password123"
}
```

### Test 3: Password in Response (Should NOT be returned)
Check that password field is never in API responses

### Test 4: Token Expiration
1. Get token
2. Wait 7+ days (or change JWT_EXPIRE to 1m for testing)
3. Try to use expired token → Should fail
