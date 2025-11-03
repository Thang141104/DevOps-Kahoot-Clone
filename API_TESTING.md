# API Testing Guide

## ⚠️ Important: Correct API Endpoints
All auth endpoints use `/api/auth/*` (single auth), NOT `/api/auth/auth/*` (double auth).

## Test Auth Service với Postman/cURL

### 1. Health Check
```bash
GET http://localhost:3001/health
```

### 2. Register User
```bash
POST http://localhost:3000/api/auth/register
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
POST http://localhost:3000/api/auth/verify-otp
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
POST http://localhost:3000/api/auth/resend-otp
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
POST http://localhost:3000/api/auth/login
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
GET http://localhost:3000/api/auth/me
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

Invoke-RestMethod -Uri "http://localhost:3000/api/auth/register" `
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

$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
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

Invoke-RestMethod -Uri "http://localhost:3000/api/auth/me" `
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

    Invoke-RestMethod -Uri "http://localhost:3000/api/auth/register" `
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

---

## Test Quiz Service (Port 3002)

### 1. Health Check
```bash
GET http://localhost:3002/health
```

### 2. Create Quiz
```bash
POST http://localhost:3000/api/quiz/quizzes
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "General Knowledge Quiz",
  "description": "Test your knowledge!",
  "category": "General",
  "difficulty": "medium",
  "questions": [
    {
      "question": "What is the capital of France?",
      "type": "single",
      "options": ["London", "Berlin", "Paris", "Madrid"],
      "correctAnswer": 2,
      "points": 100,
      "timeLimit": 30
    },
    {
      "question": "Is Earth flat?",
      "type": "truefalse",
      "options": ["True", "False"],
      "correctAnswer": 1,
      "points": 50,
      "timeLimit": 15
    }
  ]
}

Response:
{
  "_id": "quiz123",
  "title": "General Knowledge Quiz",
  "description": "Test your knowledge!",
  "createdBy": "507f1f77bcf86cd799439011",
  "questions": [...],
  "createdAt": "2025-11-01T...",
  "updatedAt": "2025-11-01T..."
}
```

### 3. Get All Quizzes (Public)
```bash
GET http://localhost:3000/api/quiz/quizzes
```

### 4. Get My Quizzes (Created by user)
```bash
GET http://localhost:3000/api/quiz/quizzes?createdBy={userId}
Authorization: Bearer {token}
```

### 5. Get Quiz by ID
```bash
GET http://localhost:3000/api/quiz/quizzes/{quizId}
```

### 6. Update Quiz
```bash
PUT http://localhost:3000/api/quiz/quizzes/{quizId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "Updated Quiz Title",
  "description": "Updated description",
  "questions": [...]
}
```

### 7. Delete Quiz
```bash
DELETE http://localhost:3000/api/quiz/quizzes/{quizId}
Authorization: Bearer {token}
```

### 8. Star/Unstar Quiz
```bash
POST http://localhost:3000/api/quiz/quizzes/{quizId}/star
Authorization: Bearer {token}
```

### PowerShell - Quiz Service Test
```powershell
$token = "your_jwt_token_here"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Create Quiz
$quiz = @{
    title = "PowerShell Test Quiz"
    description = "Created via PowerShell"
    category = "Technology"
    difficulty = "easy"
    questions = @(
        @{
            question = "What is 2+2?"
            type = "single"
            options = @("3", "4", "5", "6")
            correctAnswer = 1
            points = 100
            timeLimit = 20
        }
    )
} | ConvertTo-Json -Depth 10

$result = Invoke-RestMethod -Uri "http://localhost:3000/api/quiz/quizzes" `
    -Method POST -Headers $headers -Body $quiz

Write-Host "Quiz created with ID: $($result._id)"

# Get All Quizzes
$quizzes = Invoke-RestMethod -Uri "http://localhost:3000/api/quiz/quizzes" -Method GET
Write-Host "Total quizzes: $($quizzes.Count)"
```

---

## Test Game Service (Port 3003)

### 1. Health Check
```bash
GET http://localhost:3003/health
```

### 2. Create Game Session
```bash
POST http://localhost:3000/api/game/games
Authorization: Bearer {token}
Content-Type: application/json

{
  "quizId": "quiz123",
  "hostId": "507f1f77bcf86cd799439011",
  "hostName": "testuser",
  "settings": {
    "maxPlayers": 50,
    "showLeaderboard": true,
    "randomizeQuestions": false,
    "randomizeAnswers": true
  }
}

Response:
{
  "_id": "game123",
  "pin": "123456",
  "quizId": "quiz123",
  "hostId": "507f1f77bcf86cd799439011",
  "hostName": "testuser",
  "status": "waiting",
  "players": [],
  "createdAt": "2025-11-01T..."
}
```

### 3. Get Game by PIN
```bash
GET http://localhost:3000/api/game/games/pin/{pin}

Response:
{
  "_id": "game123",
  "pin": "123456",
  "quizId": "quiz123",
  "status": "waiting",
  "players": [...]
}
```

### 4. Get Game by ID
```bash
GET http://localhost:3000/api/game/games/{gameId}
Authorization: Bearer {token}
```

### 5. Get My Hosted Games
```bash
GET http://localhost:3000/api/game/games?hostId={userId}&status=finished
Authorization: Bearer {token}

Response:
{
  "games": [
    {
      "_id": "game123",
      "pin": "123456",
      "quizTitle": "General Knowledge Quiz",
      "status": "finished",
      "playerCount": 5,
      "createdAt": "2025-11-01T...",
      "finishedAt": "2025-11-01T..."
    }
  ]
}
```

### 6. Delete Game
```bash
DELETE http://localhost:3000/api/game/games/{gameId}
Authorization: Bearer {token}
```

### 7. WebSocket Events (Socket.io)
Connect to: `http://localhost:3003`

**Host Events:**
```javascript
// Start game
socket.emit('start-game', { pin: '123456' });

// Next question
socket.emit('next-question', { pin: '123456' });

// End game
socket.emit('end-game', { pin: '123456' });
```

**Player Events:**
```javascript
// Join game
socket.emit('join-game', { 
  pin: '123456', 
  playerName: 'Player1',
  avatar: 'avatar1'
});

// Submit answer
socket.emit('submit-answer', {
  pin: '123456',
  playerId: 'socket_id',
  answer: 2,
  timeSpent: 15
});
```

### PowerShell - Game Service Test
```powershell
$token = "your_jwt_token_here"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Create Game
$game = @{
    quizId = "quiz123"
    hostId = "507f1f77bcf86cd799439011"
    hostName = "testuser"
    settings = @{
        maxPlayers = 50
        showLeaderboard = $true
        randomizeQuestions = $false
        randomizeAnswers = $true
    }
} | ConvertTo-Json -Depth 10

$result = Invoke-RestMethod -Uri "http://localhost:3000/api/game/games" `
    -Method POST -Headers $headers -Body $game

Write-Host "Game created with PIN: $($result.pin)"

# Get game by PIN
$gameData = Invoke-RestMethod -Uri "http://localhost:3000/api/game/games/pin/$($result.pin)" `
    -Method GET

Write-Host "Game status: $($gameData.status)"
Write-Host "Players: $($gameData.players.Count)"
```

---

## Test User Service (Port 3004)

### Automated Test Script
```powershell
cd services/user-service
node test-api.js
```
**Expected:** ✅ All tests passed: 10/10

### Manual API Tests

#### 1. Health Check
```bash
GET http://localhost:3004/health
```

#### 2. Create Profile (Auto-created on registration)
```bash
POST http://localhost:3000/api/user/users/{userId}/profile
Content-Type: application/json

{
  "username": "testuser",
  "email": "test@example.com",
  "displayName": "Test User",
  "bio": "Hello World!"
}

Response:
{
  "userId": "507f1f77bcf86cd799439011",
  "username": "testuser",
  "email": "test@example.com",
  "displayName": "Test User",
  "bio": "Hello World!",
  "level": 1,
  "experience": 0,
  "avatarUrl": null,
  "createdAt": "2025-11-01T..."
}
```

#### 3. Get Profile
```bash
GET http://localhost:3000/api/user/users/{userId}/profile
Authorization: Bearer {token}
```

#### 4. Update Profile
```bash
PUT http://localhost:3000/api/user/users/{userId}/profile
Authorization: Bearer {token}
Content-Type: application/json

{
  "displayName": "Updated Name",
  "bio": "Updated bio",
  "settings": {
    "emailNotifications": true,
    "showStats": true
  }
}
```

#### 5. Upload Avatar
```bash
POST http://localhost:3000/api/user/users/{userId}/avatar
Authorization: Bearer {token}
Content-Type: multipart/form-data

[File upload: image/jpeg, max 5MB]

Response:
{
  "avatarUrl": "/uploads/avatars/507f1f77bcf86cd799439011_1730448000000.jpg"
}
```

#### 6. Delete Avatar
```bash
DELETE http://localhost:3000/api/user/users/{userId}/avatar
Authorization: Bearer {token}
```

#### 7. Get User Stats
```bash
GET http://localhost:3000/api/user/users/{userId}/stats
Authorization: Bearer {token}

Response:
{
  "userId": "507f1f77bcf86cd799439011",
  "gamesPlayed": 10,
  "gamesHosted": 5,
  "quizzesCreated": 3,
  "totalQuestions": 45,
  "avgAccuracy": 85.5,
  "bestScore": 950,
  "totalPoints": 8500,
  "totalPlayersHosted": 25,
  "avgPlayersPerGame": 5
}
```

#### 8. Sync Stats (Refresh from other services)
```bash
POST http://localhost:3000/api/user/users/{userId}/stats/sync
Authorization: Bearer {token}

Response:
{
  "message": "Stats synced successfully",
  "stats": {...}
}
```

#### 9. Get Achievements
```bash
GET http://localhost:3000/api/user/users/{userId}/achievements
Authorization: Bearer {token}

Response:
{
  "achievements": [
    {
      "id": "first_quiz",
      "name": "Quiz Creator",
      "description": "Create your first quiz",
      "category": "quiz_master",
      "icon": "🎯",
      "requirement": 1,
      "unlocked": true,
      "progress": 3,
      "unlockedAt": "2025-11-01T..."
    }
  ],
  "unlockedCount": 5,
  "totalCount": 22
}
```

#### 10. Get Activity Feed
```bash
GET http://localhost:3000/api/user/users/{userId}/activity?limit=20
Authorization: Bearer {token}

Response:
{
  "activities": [
    {
      "type": "quiz_created",
      "description": "Created quiz: General Knowledge",
      "timestamp": "2025-11-01T...",
      "metadata": { "quizId": "quiz123" }
    }
  ],
  "total": 15
}
```

#### 11. Search Users
```bash
GET http://localhost:3000/api/user/users/search?q=test&limit=10
Authorization: Bearer {token}

Response:
{
  "users": [
    {
      "userId": "507f1f77bcf86cd799439011",
      "username": "testuser",
      "displayName": "Test User",
      "level": 5,
      "experience": 2500,
      "avatarUrl": null
    }
  ],
  "total": 1
}
```

#### 12. Get Leaderboard
```bash
GET http://localhost:3000/api/user/users/leaderboard?limit=10&sortBy=experience
Authorization: Bearer {token}

Response:
{
  "leaderboard": [
    {
      "rank": 1,
      "userId": "...",
      "username": "topplayer",
      "displayName": "Top Player",
      "level": 10,
      "experience": 10000,
      "avatarUrl": "...",
      "stats": {
        "gamesPlayed": 100,
        "quizzesCreated": 20,
        "avgAccuracy": 95
      }
    }
  ],
  "total": 50,
  "userRank": 15
}
```

#### 13. Get/Update Preferences
```bash
# Get Preferences
GET http://localhost:3000/api/user/users/{userId}/preferences
Authorization: Bearer {token}

# Update Preferences
PUT http://localhost:3000/api/user/users/{userId}/preferences
Authorization: Bearer {token}
Content-Type: application/json

{
  "theme": "dark",
  "language": "en",
  "notifications": {
    "email": true,
    "push": false
  },
  "privacy": {
    "showProfile": true,
    "showStats": true
  }
}
```

### PowerShell - User Service Test
```powershell
$token = "your_jwt_token_here"
$userId = "507f1f77bcf86cd799439011"
$headers = @{
    "Authorization" = "Bearer $token"
}

# Get Profile
$profile = Invoke-RestMethod -Uri "http://localhost:3000/api/user/users/$userId/profile" `
    -Method GET -Headers $headers
Write-Host "Profile: $($profile.displayName), Level: $($profile.level)"

# Get Stats
$stats = Invoke-RestMethod -Uri "http://localhost:3000/api/user/users/$userId/stats" `
    -Method GET -Headers $headers
Write-Host "Games Played: $($stats.gamesPlayed), Quizzes: $($stats.quizzesCreated)"

# Get Achievements
$achievements = Invoke-RestMethod -Uri "http://localhost:3000/api/user/users/$userId/achievements" `
    -Method GET -Headers $headers
Write-Host "Achievements: $($achievements.unlockedCount)/$($achievements.totalCount)"

# Search Users
$search = Invoke-RestMethod -Uri "http://localhost:3000/api/user/users/search?q=test" `
    -Method GET -Headers $headers
Write-Host "Found $($search.total) users"

# Leaderboard
$leaderboard = Invoke-RestMethod -Uri "http://localhost:3000/api/user/users/leaderboard?limit=5" `
    -Method GET -Headers $headers
Write-Host "Top 5 players:"
$leaderboard.leaderboard | ForEach-Object {
    Write-Host "$($_.rank). $($_.displayName) - Level $($_.level)"
}
```

---

## Test Analytics Service (Port 3005)

### 1. Health Check
```bash
GET http://localhost:3005/health
```

### 2. Track Event
```bash
POST http://localhost:3000/api/analytics/events
Authorization: Bearer {token}
Content-Type: application/json

{
  "eventType": "quiz_completed",
  "userId": "507f1f77bcf86cd799439011",
  "metadata": {
    "quizId": "quiz123",
    "score": 850,
    "accuracy": 85,
    "timeSpent": 120,
    "correctAnswers": 8,
    "totalQuestions": 10
  }
}

Response:
{
  "success": true,
  "eventId": "event123",
  "message": "Event tracked successfully"
}
```

### 3. Get All Events
```bash
GET http://localhost:3000/api/analytics/events?limit=50&userId={userId}
Authorization: Bearer {token}

Response:
{
  "events": [
    {
      "_id": "event123",
      "eventType": "quiz_completed",
      "userId": "507f1f77bcf86cd799439011",
      "timestamp": "2025-11-01T...",
      "metadata": {...}
    }
  ],
  "total": 45
}
```

### 4. Get Event Summary
```bash
GET http://localhost:3000/api/analytics/events/summary
Authorization: Bearer {token}

Response:
{
  "summary": {
    "user_login": 150,
    "user_register": 50,
    "quiz_created": 75,
    "quiz_completed": 300,
    "game_started": 80,
    "game_ended": 75,
    "achievement_unlocked": 120
  },
  "totalEvents": 850
}
```

### 5. Get Global Stats
```bash
GET http://localhost:3000/api/analytics/stats/global
Authorization: Bearer {token}

Response:
{
  "users": {
    "total": 150,
    "active": 45,
    "newToday": 5
  },
  "quizzes": {
    "total": 250,
    "totalPlays": 1500,
    "avgAccuracy": 78.5
  },
  "games": {
    "total": 180,
    "completed": 150,
    "active": 5,
    "totalPlayers": 890,
    "avgPlayersPerGame": 4.9
  }
}
```

### 6. Get Dashboard Data
```bash
GET http://localhost:3000/api/analytics/stats/dashboard
Authorization: Bearer {token}

Response:
{
  "overview": {
    "totalUsers": 150,
    "totalQuizzes": 250,
    "totalGames": 180,
    "activeGames": 5,
    "totalEvents": 850
  },
  "recentActivity": [
    {
      "type": "quiz_completed",
      "userId": "...",
      "userName": "testuser",
      "timestamp": "2025-11-01T12:30:00Z",
      "description": "Completed quiz: General Knowledge"
    }
  ],
  "popularQuizzes": [
    {
      "quizId": "quiz123",
      "title": "General Knowledge",
      "plays": 50,
      "avgScore": 750,
      "avgAccuracy": 85
    }
  ],
  "topPlayers": [
    {
      "userId": "...",
      "username": "topplayer",
      "level": 10,
      "gamesPlayed": 100
    }
  ]
}
```

### 7. Get User Analytics
```bash
GET http://localhost:3000/api/analytics/stats/user/{userId}
Authorization: Bearer {token}

Response:
{
  "userId": "507f1f77bcf86cd799439011",
  "profile": {
    "username": "testuser",
    "displayName": "Test User",
    "level": 5,
    "experience": 2500
  },
  "achievements": {
    "unlocked": 5,
    "total": 22,
    "recentUnlocks": [...]
  },
  "activity": {
    "gamesPlayed": 10,
    "quizzesCreated": 3,
    "totalTimeSpent": 3600,
    "loginCount": 25,
    "lastActive": "2025-11-01T..."
  },
  "performance": {
    "avgAccuracy": 85.5,
    "bestScore": 950,
    "totalPoints": 8500,
    "avgScore": 720
  }
}
```

### 8. Get Trends
```bash
GET http://localhost:3000/api/analytics/stats/trends?period=7d
Authorization: Bearer {token}

Response:
{
  "period": "7d",
  "growth": {
    "newUsers": [5, 8, 6, 10, 7, 9, 12],
    "newQuizzes": [3, 5, 4, 6, 5, 7, 8],
    "gamesPlayed": [15, 20, 18, 25, 22, 28, 30]
  },
  "performance": {
    "avgAccuracy": [78, 79, 80, 82, 81, 83, 85],
    "avgScore": [650, 680, 700, 720, 710, 740, 760]
  },
  "engagement": {
    "activeUsers": [25, 28, 30, 35, 32, 38, 40],
    "avgSessionTime": [15, 18, 16, 20, 19, 22, 21]
  },
  "labels": ["Oct 26", "Oct 27", "Oct 28", "Oct 29", "Oct 30", "Oct 31", "Nov 1"]
}
```

### 9. Get Daily Stats
```bash
GET http://localhost:3000/api/analytics/stats/daily?date=2025-11-01
Authorization: Bearer {token}

Response:
{
  "date": "2025-11-01",
  "users": {
    "new": 5,
    "active": 45,
    "total": 150
  },
  "quizzes": {
    "created": 8,
    "played": 50,
    "total": 250
  },
  "games": {
    "started": 12,
    "completed": 10,
    "total": 180
  },
  "events": {
    "total": 156,
    "byType": {...}
  }
}
```

### 10. Get Performance Report
```bash
GET http://localhost:3000/api/analytics/reports/performance?startDate=2025-10-01&endDate=2025-11-01
Authorization: Bearer {token}

Response:
{
  "period": {
    "start": "2025-10-01",
    "end": "2025-11-01"
  },
  "summary": {
    "totalUsers": 150,
    "totalQuizzes": 250,
    "totalGames": 180,
    "totalEvents": 3500
  },
  "averages": {
    "quizAccuracy": 78.5,
    "gameScore": 725,
    "sessionTime": 18,
    "usersPerDay": 5
  },
  "topPerformers": [...],
  "popularContent": [...]
}
```

### PowerShell - Analytics Service Test
```powershell
$token = "your_jwt_token_here"
$userId = "507f1f77bcf86cd799439011"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Track Event
$event = @{
    eventType = "quiz_completed"
    userId = $userId
    metadata = @{
        quizId = "quiz123"
        score = 850
        accuracy = 85
        timeSpent = 120
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/analytics/events" `
    -Method POST -Headers $headers -Body $event
Write-Host "Event tracked!"

# Get Global Stats
$stats = Invoke-RestMethod -Uri "http://localhost:3000/api/analytics/stats/global" `
    -Method GET -Headers $headers
Write-Host "Users: $($stats.users.total), Quizzes: $($stats.quizzes.total), Games: $($stats.games.total)"

# Get Dashboard
$dashboard = Invoke-RestMethod -Uri "http://localhost:3000/api/analytics/stats/dashboard" `
    -Method GET -Headers $headers
Write-Host "Active Games: $($dashboard.overview.activeGames)"
Write-Host "Recent Activities: $($dashboard.recentActivity.Count)"

# Get Trends
$trends = Invoke-RestMethod -Uri "http://localhost:3000/api/analytics/stats/trends?period=7d" `
    -Method GET -Headers $headers
Write-Host "7-Day Growth:"
Write-Host "New Users: $($trends.growth.newUsers -join ', ')"
Write-Host "Games Played: $($trends.growth.gamesPlayed -join ', ')"

# Get User Analytics
$userStats = Invoke-RestMethod -Uri "http://localhost:3000/api/analytics/stats/user/$userId" `
    -Method GET -Headers $headers
Write-Host "User Analytics:"
Write-Host "Level: $($userStats.profile.level)"
Write-Host "Games Played: $($userStats.activity.gamesPlayed)"
Write-Host "Avg Accuracy: $($userStats.performance.avgAccuracy)%"
```

---

## Complete Testing Flow

### Full System Test Script
```powershell
# Step 1: Check All Services Health
Write-Host "=== Checking All Services ===" -ForegroundColor Cyan

$services = @(
    @{Name="Gateway"; Port=3000},
    @{Name="Auth"; Port=3001},
    @{Name="Quiz"; Port=3002},
    @{Name="Game"; Port=3003},
    @{Name="User"; Port=3004},
    @{Name="Analytics"; Port=3005}
)

foreach ($service in $services) {
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:$($service.Port)/health" -ErrorAction Stop
        Write-Host "✅ $($service.Name) Service ($($service.Port)): $($health.status)" -ForegroundColor Green
    } catch {
        Write-Host "❌ $($service.Name) Service ($($service.Port)): OFFLINE" -ForegroundColor Red
    }
}

# Step 2: Register and Login
Write-Host "`n=== Testing Authentication ===" -ForegroundColor Cyan

$username = "testuser_$(Get-Random -Minimum 1000 -Maximum 9999)"
$email = "$username@example.com"

# Register
$registerBody = @{
    username = $username
    email = $email
    password = "password123"
} | ConvertTo-Json

$registerResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/register" `
    -Method POST -ContentType "application/json" -Body $registerBody
Write-Host "✅ User registered: $($registerResponse.userId)" -ForegroundColor Green

# Note: In real scenario, verify OTP from email
# For testing, get OTP from console or database

# Simulate Login (assuming OTP verified)
$loginBody = @{
    emailOrUsername = $username
    password = "password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
        -Method POST -ContentType "application/json" -Body $loginBody
    $token = $loginResponse.token
    $userId = $loginResponse.user.id
    Write-Host "✅ Login successful, token obtained" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Login skipped (OTP verification needed)" -ForegroundColor Yellow
    # Use existing token for testing
    $token = "your_existing_token_here"
    $userId = "your_existing_user_id_here"
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Step 3: Test Quiz Service
Write-Host "`n=== Testing Quiz Service ===" -ForegroundColor Cyan

$quizBody = @{
    title = "Test Quiz $(Get-Random -Minimum 100 -Maximum 999)"
    description = "Created by test script"
    category = "Test"
    difficulty = "easy"
    questions = @(
        @{
            question = "Test question?"
            type = "single"
            options = @("A", "B", "C", "D")
            correctAnswer = 1
            points = 100
            timeLimit = 30
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $quiz = Invoke-RestMethod -Uri "http://localhost:3000/api/quiz/quizzes" `
        -Method POST -Headers $headers -Body $quizBody
    Write-Host "✅ Quiz created: $($quiz._id)" -ForegroundColor Green
    $quizId = $quiz._id
} catch {
    Write-Host "❌ Quiz creation failed: $_" -ForegroundColor Red
}

# Step 4: Test Game Service
Write-Host "`n=== Testing Game Service ===" -ForegroundColor Cyan

if ($quizId) {
    $gameBody = @{
        quizId = $quizId
        hostId = $userId
        hostName = $username
        settings = @{
            maxPlayers = 50
            showLeaderboard = $true
        }
    } | ConvertTo-Json -Depth 10

    try {
        $game = Invoke-RestMethod -Uri "http://localhost:3000/api/game/games" `
            -Method POST -Headers $headers -Body $gameBody
        Write-Host "✅ Game created with PIN: $($game.pin)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Game creation failed: $_" -ForegroundColor Red
    }
}

# Step 5: Test User Service
Write-Host "`n=== Testing User Service ===" -ForegroundColor Cyan

try {
    $profile = Invoke-RestMethod -Uri "http://localhost:3000/api/user/users/$userId/profile" `
        -Method GET -Headers $headers
    Write-Host "✅ Profile retrieved: Level $($profile.level)" -ForegroundColor Green

    $stats = Invoke-RestMethod -Uri "http://localhost:3000/api/user/users/$userId/stats" `
        -Method GET -Headers $headers
    Write-Host "✅ Stats retrieved: $($stats.quizzesCreated) quizzes" -ForegroundColor Green

    $achievements = Invoke-RestMethod -Uri "http://localhost:3000/api/user/users/$userId/achievements" `
        -Method GET -Headers $headers
    Write-Host "✅ Achievements: $($achievements.unlockedCount)/$($achievements.totalCount)" -ForegroundColor Green
} catch {
    Write-Host "❌ User service test failed: $_" -ForegroundColor Red
}

# Step 6: Test Analytics Service
Write-Host "`n=== Testing Analytics Service ===" -ForegroundColor Cyan

$eventBody = @{
    eventType = "test_event"
    userId = $userId
    metadata = @{
        source = "test_script"
    }
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://localhost:3000/api/analytics/events" `
        -Method POST -Headers $headers -Body $eventBody
    Write-Host "✅ Event tracked" -ForegroundColor Green

    $globalStats = Invoke-RestMethod -Uri "http://localhost:3000/api/analytics/stats/global" `
        -Method GET -Headers $headers
    Write-Host "✅ Global stats: $($globalStats.users.total) users" -ForegroundColor Green
} catch {
    Write-Host "❌ Analytics test failed: $_" -ForegroundColor Red
}

Write-Host "`n=== Testing Complete ===" -ForegroundColor Cyan
```

---

## Troubleshooting

### Common Issues

**404 Not Found:**
- Verify service is running on correct port
- Check URL path matches routes
- Use Gateway URL for external calls

**401 Unauthorized:**
- Token expired (7 days default)
- Token not in Authorization header
- JWT_SECRET mismatch between services

**500 Internal Server Error:**
- Check service logs
- MongoDB connection issues
- Service-to-service communication failures

**ECONNREFUSED:**
- Service not running
- Wrong port number
- Firewall blocking connection

### Debug Commands
```powershell
# Check ports in use
Get-NetTCPConnection -LocalPort 3000,3001,3002,3003,3004,3005,3006 | 
    Select-Object LocalPort, State, OwningProcess

# Kill process on port
$process = Get-NetTCPConnection -LocalPort 3004 | Select-Object -ExpandProperty OwningProcess
Stop-Process -Id $process -Force

# Check MongoDB
Get-Process mongod
```

---

## Event Types (Analytics)

Available event types for tracking:
```
- user_register
- user_login
- user_logout
- profile_update
- quiz_created
- quiz_updated
- quiz_deleted
- quiz_started
- quiz_completed
- game_created
- game_started
- game_joined
- game_ended
- achievement_unlocked
- stats_synced
- avatar_uploaded
- settings_changed
- search_performed
```
