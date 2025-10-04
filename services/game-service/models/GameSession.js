const mongoose = require('mongoose');

const gameSessionSchema = new mongoose.Schema({
  pin: {
    type: String,
    required: true,
    unique: true
  },
  quizId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Quiz',
    required: true
  },
  hostId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  players: [{
    nickname: String,
    avatar: String,
    score: Number,
    answers: [{
      questionId: Number,
      answer: mongoose.Schema.Types.Mixed,
      isCorrect: Boolean,
      points: Number,
      timeSpent: Number
    }]
  }],
  status: {
    type: String,
    enum: ['waiting', 'active', 'ended'],
    default: 'waiting'
  },
  startedAt: Date,
  endedAt: Date
}, {
  timestamps: true
});

module.exports = mongoose.model('GameSession', gameSessionSchema);
