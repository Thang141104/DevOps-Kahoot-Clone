const express = require('express');
const router = express.Router();
const GameSession = require('../models/GameSession');

// Get game session by PIN
router.get('/pin/:pin', async (req, res) => {
  try {
    const session = await GameSession.findOne({ pin: req.params.pin });
    if (!session) {
      return res.status(404).json({ error: 'Game session not found' });
    }
    res.json(session);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get game session by ID
router.get('/:id', async (req, res) => {
  try {
    const session = await GameSession.findById(req.params.id).populate('quizId');
    if (!session) {
      return res.status(404).json({ error: 'Game session not found' });
    }
    res.json(session);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Save game session
router.post('/', async (req, res) => {
  try {
    const session = new GameSession(req.body);
    await session.save();
    res.status(201).json(session);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
