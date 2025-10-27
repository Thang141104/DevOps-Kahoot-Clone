# Quiz Application - Kahoot Clone

A full-stack, real-time quiz application built with React, Node.js, and MongoDB using microservices architecture.

## ⚠️ Recent Fixes
**Auth Service Issues Resolved** - See [FIXES.md](FIXES.md) for details on login/registration bug fixes.

## 🎯 Features

- **Interactive Quiz Creation**: Build quizzes with multiple question types
- **Real-time Gameplay**: Live quiz sessions with Socket.io
- **Player Management**: Join games with PIN codes
- **Live Leaderboards**: Real-time score tracking
- **Detailed Analytics**: Comprehensive result analysis
- **Responsive Design**: Works on desktop and mobile

## 🏗️ Architecture

### Microservices
- **API Gateway** (Port 3000) - Request routing and rate limiting
- **Quiz Service** (Port 3002) - Quiz CRUD operations
- **Game Service** (Port 3003) - Real-time game management
- **Auth Service** (Port 3001) - Authentication (to be implemented)
- **User Service** (Port 3004) - User management (to be implemented)
- **Analytics Service** (Port 3005) - Statistics (to be implemented)

### Tech Stack
- **Frontend**: React 18, React Router, Socket.io Client
- **Backend**: Node.js, Express, Socket.io
- **Database**: MongoDB
- **Real-time**: WebSocket (Socket.io)

## 📁 Project Structure

```
quiz-app/
├── frontend/                 # React application
│   ├── public/
│   └── src/
│       ├── pages/           # Page components
│       │   ├── Home.js
│       │   ├── Dashboard.js
│       │   ├── QuizBuilder.js
│       │   ├── Join.js
│       │   ├── LobbyHost.js
│       │   ├── LobbyPlayer.js
│       │   ├── LiveControl.js
│       │   ├── Answering.js
│       │   ├── Feedback.js
│       │   ├── Leaderboard.js
│       │   ├── EndGame.js
│       │   └── Result.js
│       ├── App.js
│       └── index.js
├── gateway/                  # API Gateway
│   └── server.js
├── services/
│   ├── quiz-service/        # Quiz management
│   │   ├── models/
│   │   ├── routes/
│   │   └── server.js
│   ├── game-service/        # Real-time game logic
│   │   ├── models/
│   │   ├── routes/
│   │   └── server.js
│   ├── auth-service/        # Authentication (TODO)
│   ├── user-service/        # User management (TODO)
│   └── analytics-service/   # Analytics (TODO)
└── README.md
```

## 🚀 Getting Started

### Prerequisites
- Node.js v16+
- MongoDB v5+
- npm or yarn

### Installation

1. **Install MongoDB**
   ```powershell
   # Download from https://www.mongodb.com/try/download/community
   # Start MongoDB
   net start MongoDB
   ```

2. **Install Dependencies**
   ```powershell
   # Frontend
   cd frontend
   npm install

   # Gateway
   cd ..\gateway
   npm install

   # Quiz Service
   cd ..\services\quiz-service
   npm install

   # Game Service
   cd ..\services\game-service
   npm install
   ```

3. **Start Services** (Open 4 terminals)
   ```powershell
   # Terminal 1 - Frontend
   cd frontend
   npm start

   # Terminal 2 - Gateway
   cd gateway
   npm run dev

   # Terminal 3 - Quiz Service
   cd services\quiz-service
   npm run dev

   # Terminal 4 - Game Service
   cd services\game-service
   npm run dev
   ```

4. **Access Application**
   - Frontend: http://localhost:3000
   - API Gateway: http://localhost:3000/api

## 📖 Usage

### Creating and Sharing a Quiz (Complete Flow)

#### 1. Create Quiz
1. Login to your account
2. Navigate to Dashboard
3. Click "New Quiz" button
4. Add quiz title and description
5. Add questions with:
   - Question text
   - Multiple choice options
   - Correct answer
   - Time limit and points
6. Click "Save Quiz"
7. Quiz appears in your Dashboard

#### 2. Start Game & Share PIN
1. In Dashboard, find your saved quiz
2. Click **"Start"** button on the quiz card
3. System creates game session and generates unique PIN
4. You're taken to Lobby Host page showing:
   - **Game PIN** (6-digit code)
   - QR code for easy joining
   - List of players joining
5. **Share the PIN** with players via:
   - Screen share
   - Chat message
   - Projector display
   - QR code scan

#### 3. Players Join
1. Players open the app
2. Click "Join with PIN"
3. Enter the 6-digit PIN
4. Choose nickname and avatar
5. Wait in lobby until host starts

#### 4. Host Controls Game
1. Wait for all players to join
2. Review player list
3. Click "Start Game" when ready
4. Control question flow
5. View live results

### Hosting a Game (Quick Version)
1. Select a quiz from Dashboard
2. Click "Start" to get PIN
3. Share PIN with players
4. Wait for players to join
5. Start game when ready

### Joining a Game
1. Click "Join with PIN"
2. Enter game PIN
3. Choose nickname and avatar
4. Wait in lobby
5. Answer questions when game starts

## 🎮 Game Flow

```
HOST FLOW:
Login → Dashboard → Create Quiz → Save → Dashboard
  ↓
Click "Start" Button → Game Session Created → Get PIN
  ↓
Lobby Host Page (Share PIN with players)
  ↓
Players Join → Review Players → Click "Start Game"
  ↓
Live Control → Control Questions → View Results
  ↓
End Game → Analytics

PLAYER FLOW:
Home Page → Join with PIN → Enter PIN
  ↓
Lobby Player Page (Wait for host)
  ↓
Game Started → Answer Questions → See Feedback
  ↓
View Leaderboard → End Game → See Results

SHARING METHODS:
- Display PIN on screen/projector
- Send PIN via chat/message
- Share QR code for scanning
- Verbal announcement
```

## 🔌 API Endpoints

### Quiz Service
- `GET /quizzes` - Get all quizzes
- `GET /quizzes/:id` - Get quiz by ID
- `POST /quizzes` - Create quiz
- `PUT /quizzes/:id` - Update quiz
- `DELETE /quizzes/:id` - Delete quiz
- `PATCH /quizzes/:id/star` - Toggle star

### Game Service
- `GET /games/pin/:pin` - Get game by PIN
- `GET /games/:id` - Get game session
- `POST /games` - Create game session

### Socket.io Events
- `create-game` - Host creates game
- `join-game` - Player joins
- `start-game` - Host starts game
- `submit-answer` - Player submits answer
- `show-leaderboard` - Display rankings
- `end-game` - End game session

## 🎨 UI Pages

1. **Home** - Landing page with features
2. **Dashboard** - Quiz management and stats
3. **Quiz Builder** - Create/edit quizzes
4. **Join** - Enter game PIN
5. **Lobby (Host)** - Wait for players
6. **Lobby (Player)** - Join confirmation
7. **Live Control** - Host manages game
8. **Answering** - Player answers questions
9. **Feedback** - Answer feedback
10. **Leaderboard** - Live rankings
11. **End Game** - Player results
12. **Result** - Detailed analytics

## 📝 TODO

- [ ] Implement Auth Service with JWT
- [ ] Add User Service for profiles
- [ ] Create Analytics Service
- [ ] Add image/video upload for questions
- [ ] Implement Redis for caching
- [ ] Add Docker support
- [ ] Write unit tests
- [ ] Set up CI/CD

## 📄 License

This project is open source and available under the MIT License.

---

⭐ See INSTALLATION.md for detailed setup instructions!
