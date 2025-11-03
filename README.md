# Quiz Application - Kahoot Clone

A full-stack, real-time quiz application built with React, Node.js, and MongoDB using microservices architecture.

## 🎉 Latest Updates
- ✅ **Centralized API Configuration** - Easy mobile device access
- ✅ **Game History Page** - View and manage past games
- ✅ **Enhanced UI** - Podium display, confetti effects, smooth animations
- ✅ **Game Status Management** - Auto-progression and manual end game
- ✅ **Code Cleanup** - Removed unused components

See [CHANGELOG.md](CHANGELOG.md) for detailed changes.

## 🎯 Features

- **Interactive Quiz Creation**: Build quizzes with multiple question types (Single Choice, Multiple Choice, True/False)
- **Real-time Gameplay**: Live quiz sessions with Socket.io and auto-progression
- **Player Management**: Join games with PIN codes
- **Live Leaderboards**: Real-time score tracking with podium display
- **Game History**: View and manage past game sessions
- **Detailed Analytics**: Comprehensive result analysis with confetti animations
- **Mobile Support**: Centralized API config for easy mobile device access
- **Responsive Design**: Works seamlessly on desktop and mobile devices

## 🏗️ Architecture

### Microservices
- **API Gateway** (Port 3000) - Request routing and rate limiting
- **Auth Service** (Port 3001) - User authentication with JWT and OTP verification
- **Quiz Service** (Port 3002) - Quiz CRUD operations
- **Game Service** (Port 3003) - Real-time game management with Socket.io
- **User Service** (Port 3004) - User profiles, stats, achievements, leaderboard
- **Analytics Service** (Port 3005) - Event tracking, statistics, trends dashboard
- **Frontend** (Port 3006) - React application

### Tech Stack
- **Frontend**: React 18, React Router v6, Socket.io Client
- **Backend**: Node.js, Express, Socket.io, Axios
- **Database**: MongoDB with Mongoose
- **Real-time**: WebSocket (Socket.io)
- **Authentication**: JWT, Nodemailer (OTP)

## 📁 Project Structure

```
quiz-app/
├── frontend/                 # React application (Port 3006)
│   ├── public/
│   └── src/
│       ├── config/          # API configuration
│       │   └── api.js       # Centralized API URLs
│       └── pages/           # Page components
│           ├── Home.js
│           ├── Login.js
│           ├── Register.js
│           ├── VerifyOTP.js
│           ├── Dashboard.js
│           ├── QuizBuilder.js
│           ├── GameHistory.js
│           ├── Join.js
│           ├── LobbyHost.js
│           ├── LobbyPlayer.js
│           ├── LiveControl.js
│           ├── Answering.js
│           ├── Feedback.js
│           └── EndGameNew.js
├── gateway/                  # API Gateway (Port 3000)
│   └── server.js
├── services/
│   ├── auth-service/        # Authentication (Port 3001)
│   │   ├── models/
│   │   ├── routes/
│   │   ├── utils/
│   │   └── server.js
│   ├── quiz-service/        # Quiz management (Port 3002)
│   │   ├── models/
│   │   ├── routes/
│   │   └── server.js
│   └── game-service/        # Real-time game logic (Port 3003)
│       ├── models/
│       ├── routes/
│       └── server.js
├── CHANGELOG.md             # Comprehensive change log
├── CONFIG_README.md         # Environment configuration guide
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

   # User Service
   cd ..\services\user-service
   npm install

   # Analytics Service
   cd ..\services\analytics-service
   npm install
   ```

3. **Start Services** (Open 7 terminals)
   ```powershell
   # Terminal 1 - Gateway
   cd gateway
   npm run dev

   # Terminal 2 - Auth Service
   cd services\auth-service
   npm run dev

   # Terminal 3 - Quiz Service
   cd services\quiz-service
   npm run dev

   # Terminal 4 - Game Service
   cd services\game-service
   npm run dev

   # Terminal 5 - User Service
   cd services\user-service
   npm run dev

   # Terminal 6 - Analytics Service
   cd services\analytics-service
   npm run dev

   # Terminal 7 - Frontend
   cd frontend
   npm start
   ```

4. **Configure Environment** (Optional - for mobile access)
   
   Create `frontend/.env`:
   ```properties
   PORT=3006
   REACT_APP_API_URL=http://localhost:3000
   REACT_APP_SOCKET_URL=http://localhost:3003
   ```
   
   For mobile access, replace `localhost` with your computer's IP address.
   See [CONFIG_README.md](frontend/CONFIG_README.md) for details.

5. **Access Application**
   - Frontend: http://localhost:3006
   - API Gateway: http://localhost:3000
   - Analytics Dashboard: http://localhost:3006/analytics

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
Register → Verify OTP → Login → Dashboard
  ↓
Create Quiz → Save → Dashboard → Click "Start"
  ↓
Game Session Created (Auto-generate PIN)
  ↓
Lobby Host Page (Share PIN with players)
  ↓
Players Join → Review Players → Click "Start Game"
  ↓
Live Control → Auto-progression through questions
  ↓
End Game (Auto or Manual) → Status: 'finished'
  ↓
View Results → Game History

PLAYER FLOW:
Home Page → Join with PIN → Enter PIN + Nickname
  ↓
Lobby Player Page (Wait for host to start)
  ↓
Game Started → Answer Questions → See Feedback
  ↓
View Leaderboard → End Game → See Personal Results
  ↓
Play Again option

SHARING METHODS:
- Display PIN on screen/projector
- Send PIN via chat/message  
- QR code for scanning (future)
- Verbal announcement

GAME FEATURES:
- Auto-progression: Timer-based question advancement
- Manual end: Host can stop game anytime
- Real-time sync: Socket.io for instant updates
- Score calculation: Base points + time bonus
```

## 🔌 API Endpoints

### Auth Service (Port 3001)
- `POST /register` - Register new user
- `POST /login` - User login
- `POST /verify-otp` - Verify OTP code
- `POST /resend-otp` - Resend OTP

### Quiz Service (Port 3002)
- `GET /quizzes` - Get all quizzes
- `GET /quizzes/:id` - Get quiz by ID
- `POST /quizzes` - Create quiz
- `PUT /quizzes/:id` - Update quiz
- `DELETE /quizzes/:id` - Delete quiz
- `PATCH /quizzes/:id/star` - Toggle star

### Game Service (Port 3003)
- `GET /games` - Get all game sessions (with filters)
- `GET /games/pin/:pin` - Get game by PIN
- `GET /games/:id` - Get game by ID
- `POST /games` - Create game session (auto-generate PIN)
- `DELETE /games/:id` - Delete game session

### Socket.io Events (Port 3003)
**Host Events:**
- `host-join` - Host joins game room
- `start-game` - Host starts game
- `game-ended` - Host manually ends game

**Player Events:**
- `join-game` - Player joins with PIN
- `player-answer` - Player submits answer

**Broadcast Events:**
- `player-joined` - New player joined
- `game-started` - Game has started
- `question-started` - New question begins
- `answer-revealed` - Show correct answer
- `game-finished` - Game completed

## 🎨 UI Pages

1. **Home** - Landing page with features
2. **Login** - User authentication
3. **Register** - New user signup
4. **Verify OTP** - Email verification
5. **Dashboard** - Quiz management and game history
6. **Quiz Builder** - Create/edit quizzes (supports 4-7 options for Multiple Choice)
7. **Game History** - View and manage past games with filters
8. **Join** - Enter game PIN
9. **Lobby Host** - Wait for players and display PIN
10. **Lobby Player** - Join confirmation
11. **Live Control** - Host manages game with auto-progression
12. **Answering** - Player answers questions (enhanced UI)
13. **Feedback** - Answer feedback with animations
14. **End Game** - Results with podium display and confetti

## 📝 TODO

### In Progress
- [ ] LiveControl UI improvements (animated charts, real-time stats)
- [ ] Background music and sound effects

### Planned Features
- [ ] User Service for detailed profiles
- [ ] Analytics Service for advanced statistics
- [ ] Image/video upload for questions
- [ ] Quiz sharing with QR codes
- [ ] Export game results to CSV/PDF
- [ ] Quiz templates and categories
- [ ] Achievements and badges

### Technical Improvements
- [ ] Redis for caching and session management
- [ ] Docker and Kubernetes deployment
- [ ] Comprehensive unit and integration tests
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Performance optimization
- [ ] Security audit and enhancements

## 📚 Documentation

- **[CHANGELOG.md](CHANGELOG.md)** - Detailed change history
- **[CONFIG_README.md](frontend/CONFIG_README.md)** - Environment configuration guide
- **[INSTALLATION.md](INSTALLATION.md)** - Detailed setup instructions
- **[API_TESTING.md](API_TESTING.md)** - API testing guide
- **[USER_GUIDE.md](USER_GUIDE.md)** - User manual

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## 🐛 Bug Reports

Found a bug? Please open an issue with:
- Description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)

---

⭐ **Star this repo** if you find it helpful!

📖 See **[INSTALLATION.md](INSTALLATION.md)** for detailed setup instructions!

🎉 See **[CHANGELOG.md](CHANGELOG.md)** for recent updates and improvements!
