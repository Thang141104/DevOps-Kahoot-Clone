const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB connection
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('✅ MongoDB connected'))
.catch(err => console.error('❌ MongoDB connection error:', err));

// Game state storage (in-memory, can be moved to Redis for production)
const games = new Map();

// Socket.io connection
io.on('connection', (socket) => {
  console.log('🔌 Client connected:', socket.id);

  // Host creates a game
  socket.on('create-game', (data) => {
    const pin = generatePin();
    const game = {
      pin,
      quizId: data.quizId,
      host: socket.id,
      players: [],
      currentQuestion: 0,
      status: 'waiting', // waiting, active, ended
      responses: []
    };
    
    games.set(pin, game);
    socket.join(pin);
    socket.emit('game-created', { pin, game });
    console.log(`🎮 Game created with PIN: ${pin}`);
  });

  // Player joins game
  socket.on('join-game', (data) => {
    const { pin, nickname, avatar } = data;
    const game = games.get(pin);

    if (!game) {
      return socket.emit('error', { message: 'Game not found' });
    }

    if (game.status !== 'waiting') {
      return socket.emit('error', { message: 'Game already started' });
    }

    const player = {
      id: socket.id,
      nickname,
      avatar,
      score: 0,
      answers: []
    };

    game.players.push(player);
    socket.join(pin);
    
    // Notify all clients in the game
    io.to(pin).emit('player-joined', { player, players: game.players });
    socket.emit('joined-game', { game, player });
    
    console.log(`👤 ${nickname} joined game ${pin}`);
  });

  // Host starts game
  socket.on('start-game', (data) => {
    const { pin } = data;
    const game = games.get(pin);

    if (!game || game.host !== socket.id) {
      return socket.emit('error', { message: 'Unauthorized' });
    }

    game.status = 'active';
    io.to(pin).emit('game-started', { game });
    
    // Start first question
    setTimeout(() => {
      io.to(pin).emit('next-question', {
        questionNumber: 1,
        question: data.questions[0]
      });
    }, 3000);

    console.log(`▶️ Game ${pin} started`);
  });

  // Player submits answer
  socket.on('submit-answer', (data) => {
    const { pin, questionId, answer, timeSpent } = data;
    const game = games.get(pin);

    if (!game) {
      return socket.emit('error', { message: 'Game not found' });
    }

    const player = game.players.find(p => p.id === socket.id);
    if (!player) {
      return socket.emit('error', { message: 'Player not found' });
    }

    // Calculate points based on correctness and speed
    const isCorrect = checkAnswer(answer, data.correctAnswer);
    const points = isCorrect ? calculatePoints(data.maxPoints, timeSpent, data.timeLimit) : 0;

    player.score += points;
    player.answers.push({
      questionId,
      answer,
      isCorrect,
      points,
      timeSpent
    });

    game.responses.push({
      playerId: socket.id,
      answer,
      isCorrect,
      points
    });

    // Notify host about response
    io.to(game.host).emit('answer-received', {
      playerId: socket.id,
      nickname: player.nickname,
      answered: game.responses.length,
      total: game.players.length
    });

    // Send feedback to player
    socket.emit('answer-feedback', {
      isCorrect,
      points,
      correctAnswer: data.correctAnswer
    });

    console.log(`✅ ${player.nickname} answered question ${questionId}`);
  });

  // Show leaderboard
  socket.on('show-leaderboard', (data) => {
    const { pin } = data;
    const game = games.get(pin);

    if (!game) return;

    const leaderboard = game.players
      .map(p => ({
        nickname: p.nickname,
        avatar: p.avatar,
        score: p.score
      }))
      .sort((a, b) => b.score - a.score);

    io.to(pin).emit('leaderboard-update', { leaderboard });
  });

  // End game
  socket.on('end-game', (data) => {
    const { pin } = data;
    const game = games.get(pin);

    if (!game || game.host !== socket.id) {
      return socket.emit('error', { message: 'Unauthorized' });
    }

    game.status = 'ended';
    
    const finalResults = {
      players: game.players.map(p => ({
        nickname: p.nickname,
        avatar: p.avatar,
        score: p.score,
        answers: p.answers
      })).sort((a, b) => b.score - a.score)
    };

    io.to(pin).emit('game-ended', { results: finalResults });
    
    console.log(`🏁 Game ${pin} ended`);
  });

  socket.on('disconnect', () => {
    console.log('🔌 Client disconnected:', socket.id);
    
    // Remove player from games
    games.forEach((game, pin) => {
      const playerIndex = game.players.findIndex(p => p.id === socket.id);
      if (playerIndex !== -1) {
        const player = game.players[playerIndex];
        game.players.splice(playerIndex, 1);
        io.to(pin).emit('player-left', { 
          playerId: socket.id, 
          nickname: player.nickname,
          players: game.players 
        });
      }
    });
  });
});

// Helper functions
function generatePin() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function checkAnswer(playerAnswer, correctAnswer) {
  if (Array.isArray(correctAnswer)) {
    return JSON.stringify(playerAnswer.sort()) === JSON.stringify(correctAnswer.sort());
  }
  return playerAnswer === correctAnswer;
}

function calculatePoints(maxPoints, timeSpent, timeLimit) {
  // Award more points for faster answers
  const timeBonus = 1 - (timeSpent / timeLimit) * 0.5;
  return Math.round(maxPoints * timeBonus);
}

// REST API routes
const gameRoutes = require('./routes/game.routes');
app.use('/games', gameRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'game-service',
    activeGames: games.size,
    timestamp: new Date().toISOString() 
  });
});

const PORT = process.env.PORT || 3003;
server.listen(PORT, () => {
  console.log(`🎮 Game Service running on port ${PORT}`);
});
