# Quiz Application - Installation Guide

## Prerequisites
- Node.js (v16 or higher)
- MongoDB (v5 or higher)
- npm or yarn

## Installation Steps

### 1. Install MongoDB
Download and install MongoDB from: https://www.mongodb.com/try/download/community

### 2. Clone and Setup

```powershell
cd C:\quiz-app
```

### 3. Install Dependencies

#### Frontend
```powershell
cd frontend
npm install
```

#### API Gateway
```powershell
cd ..\gateway
npm install
```

#### Auth Service
```powershell
cd ..\services\auth-service
npm install
```

#### Quiz Service
```powershell
cd ..\services\quiz-service
npm install
```

#### Game Service
```powershell
cd ..\services\game-service
npm install
```

### 4. Configure Environment Variables
All `.env` files are already created. Update them if needed:
- `gateway/.env`
- `services/auth-service/.env` - **IMPORTANT: Configure email settings** (see EMAIL_SETUP.md)
- `services/quiz-service/.env`
- `services/game-service/.env`

### 5. Start MongoDB
```powershell
# Start MongoDB service
net start MongoDB
```

### 6. Start Services

Open multiple PowerShell terminals:

#### Terminal 1 - Frontend
```powershell
cd C:\quiz-app\frontend
npm start
```

#### Terminal 2 - API Gateway
```powershell
cd C:\quiz-app\gateway
npm run dev
```

#### Terminal 3 - Auth Service
```powershell
cd C:\quiz-app\services\auth-service
npm run dev
```

#### Terminal 4 - Quiz Service
```powershell
cd C:\quiz-app\services\quiz-service
npm run dev
```

#### Terminal 5 - Game Service
```powershell
cd C:\quiz-app\services\game-service
npm run dev
```

### 7. Access the Application
- **Frontend**: http://localhost:3000
- **API Gateway**: http://localhost:3000/api
- **Auth Service**: http://localhost:3001
- **Quiz Service**: http://localhost:3002
- **Game Service**: http://localhost:3003

## Quick Start Script

Create a file `start-all.ps1` in the root directory:

```powershell
# Start all services
$jobs = @()

# Start Quiz Service
$jobs += Start-Job -ScriptBlock {
    cd C:\quiz-app\services\quiz-service
    npm run dev
}

# Start Game Service
$jobs += Start-Job -ScriptBlock {
    cd C:\quiz-app\services\game-service
    npm run dev
}

# Start API Gateway
$jobs += Start-Job -ScriptBlock {
    cd C:\quiz-app\gateway
    npm run dev
}

# Start Frontend
$jobs += Start-Job -ScriptBlock {
    cd C:\quiz-app\frontend
    npm start
}

Write-Host "All services started!" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop all services" -ForegroundColor Yellow

# Wait for all jobs
$jobs | Wait-Job
```

Run with:
```powershell
.\start-all.ps1
```

## Testing the Application

1. Open browser and go to http://localhost:3000
2. Click "Create Quiz" to build a quiz
3. Start a game and note the PIN
4. Open another browser/incognito window
5. Click "Join with PIN" and enter the PIN
6. Play the quiz!

## Troubleshooting

### Port Already in Use
```powershell
# Find process using port (example: 3000)
netstat -ano | findstr :3000

# Kill process
taskkill /PID <PID> /F
```

### MongoDB Connection Error
```powershell
# Check MongoDB service status
sc query MongoDB

# Start MongoDB if not running
net start MongoDB
```

### Module Not Found
```powershell
# Clear npm cache and reinstall
npm cache clean --force
rm -r node_modules
npm install
```

## Architecture Overview

```
┌─────────────┐
│   React     │
│  Frontend   │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│     API     │
│   Gateway   │
└──────┬──────┘
       │
       ├─────────────┬──────────────┬─────────────┐
       ↓             ↓              ↓             ↓
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│   Quiz   │  │   Game   │  │   User   │  │Analytics │
│ Service  │  │ Service  │  │ Service  │  │ Service  │
└─────┬────┘  └─────┬────┘  └─────┬────┘  └─────┬────┘
      │             │              │             │
      └─────────────┴──────────────┴─────────────┘
                       │
                       ↓
                 ┌──────────┐
                 │ MongoDB  │
                 └──────────┘
```

## Features Implemented

### Frontend Pages
✅ Home - Landing page
✅ Dashboard - Quiz management
✅ Quiz Builder - Create/edit quizzes
✅ Join - Enter game PIN
✅ Lobby (Host) - Wait for players
✅ Lobby (Player) - Join confirmation
✅ Live Control - Host view during game
✅ Answering - Player answer view
✅ Feedback - Answer feedback
✅ Leaderboard - Live rankings
✅ End Game - Final results
✅ Result - Detailed analytics

### Backend Services
✅ API Gateway - Request routing
✅ Quiz Service - Quiz CRUD operations
✅ Game Service - Real-time game management with Socket.io

### Key Technologies
- **Frontend**: React, React Router, Socket.io Client
- **Backend**: Node.js, Express, Socket.io
- **Database**: MongoDB with Mongoose
- **Architecture**: Microservices

## Next Steps

To complete the application, you should implement:

1. **Auth Service** - User authentication with JWT
2. **User Service** - User profile management
3. **Analytics Service** - Quiz statistics and insights
4. **File Upload** - Image/video support for questions
5. **Redis** - For caching and session management
6. **Docker** - Containerization
7. **CI/CD** - Automated deployment

## Support

For issues or questions, check:
- MongoDB logs: `C:\Program Files\MongoDB\Server\<version>\log\`
- Service logs in respective terminal windows
- Browser console for frontend errors
