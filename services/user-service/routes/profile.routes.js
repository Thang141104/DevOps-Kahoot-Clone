const express = require('express');
const router = express.Router();
const UserProfile = require('../models/UserProfile');
const { authMiddleware } = require('../middleware/auth.middleware');
const { validateProfileUpdate } = require('../middleware/validation.middleware');
const { upload, handleUploadError } = require('../middleware/upload.middleware');
const { processImage, deleteImage, getImageUrl } = require('../utils/imageUpload');
const { syncUserStats } = require('../utils/statsCalculator');
const path = require('path');

// Create user profile (called from auth service)
router.post('/:userId/profile', async (req, res) => {
  try {
    const { userId } = req.params;
    const { username, email, displayName, bio } = req.body;
    
    // Check if profile already exists
    let profile = await UserProfile.findOne({ userId });
    
    if (profile) {
      return res.status(400).json({ 
        error: 'Profile already exists',
        message: 'User profile already created' 
      });
    }
    
    // Create new profile
    profile = new UserProfile({
      userId,
      username,
      email,
      displayName: displayName || username,
      bio: bio || '',
      lastActiveAt: new Date()
    });
    
    await profile.save();
    
    console.log(`✅ Profile created for user ${userId}`);
    
    // Return profile directly (not nested) for easier consumption
    res.status(201).json(profile);
  } catch (error) {
    console.error('Error creating profile:', error);
    res.status(500).json({ 
      error: 'Server error',
      message: error.message 
    });
  }
});

// Get user profile (auto-creates if not exists)
router.get('/:userId/profile', async (req, res) => {
  try {
    const { userId } = req.params;
    
    let profile = await UserProfile.findOne({ userId });
    
    // Auto-create profile if doesn't exist
    if (!profile) {
      console.log(`📝 Profile not found for user ${userId}, creating default profile...`);
      
      // Create default profile with minimal info
      // The user can update it later
      profile = new UserProfile({
        userId,
        username: `User_${userId.substring(0, 6)}`, // Use first 6 chars of userId
        email: '',
        displayName: `User ${userId.substring(0, 6)}`,
        bio: '',
        lastActiveAt: new Date()
      });
      
      await profile.save();
      console.log(`✅ Auto-created profile for user ${userId}`);
    }
    
    // Sync stats from other services (don't fail if this fails)
    try {
      profile = await syncUserStats(profile);
    } catch (syncError) {
      console.error('Stats sync failed:', syncError.message);
      // Continue with non-synced profile
    }
    
    res.json(profile);
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ 
      error: 'Server error',
      message: error.message 
    });
  }
});

// Create or update user profile
router.put('/:userId/profile', authMiddleware, validateProfileUpdate, async (req, res) => {
  try {
    const { userId } = req.params;
    const { displayName, bio } = req.body;
    
    // Check if user owns this profile
    if (req.user.id !== userId) {
      return res.status(403).json({ 
        error: 'Forbidden',
        message: 'You can only update your own profile' 
      });
    }
    
    let profile = await UserProfile.findOne({ userId });
    
    if (!profile) {
      // Create new profile if doesn't exist
      profile = new UserProfile({
        userId,
        username: req.user.username,
        email: req.user.email,
        displayName: displayName || req.user.username
      });
    }
    
    // Update fields
    if (displayName !== undefined) {
      profile.displayName = displayName.trim();
    }
    
    if (bio !== undefined) {
      profile.bio = bio.trim();
    }
    
    profile.lastActiveAt = new Date();
    
    await profile.save();
    
    res.json({
      message: 'Profile updated successfully',
      profile
    });
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ 
      error: 'Server error',
      message: error.message 
    });
  }
});

// Upload avatar
router.post('/:userId/avatar', authMiddleware, upload.single('avatar'), handleUploadError, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Check if user owns this profile
    if (req.user.id !== userId) {
      return res.status(403).json({ 
        error: 'Forbidden',
        message: 'You can only update your own avatar' 
      });
    }
    
    if (!req.file) {
      return res.status(400).json({ 
        error: 'No file uploaded',
        message: 'Please select an image to upload' 
      });
    }
    
    // Process image (resize, compress)
    const processedPath = await processImage(req.file.path, {
      width: 400,
      height: 400,
      quality: 80
    });
    
    // Get or create profile
    let profile = await UserProfile.findOne({ userId });
    
    if (!profile) {
      profile = new UserProfile({
        userId,
        username: req.user.username,
        email: req.user.email
      });
    }
    
    // Delete old avatar if exists
    if (profile.avatarUrl) {
      const oldPath = path.join(__dirname, '..', profile.avatarUrl);
      await deleteImage(oldPath);
    }
    
    // Update avatar URL
    profile.avatarUrl = getImageUrl(processedPath);
    profile.lastActiveAt = new Date();
    
    await profile.save();
    
    res.json({
      message: 'Avatar uploaded successfully',
      avatarUrl: profile.avatarUrl
    });
  } catch (error) {
    console.error('Error uploading avatar:', error);
    res.status(500).json({ 
      error: 'Upload failed',
      message: error.message 
    });
  }
});

// Delete avatar
router.delete('/:userId/avatar', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Check if user owns this profile
    if (req.user.id !== userId) {
      return res.status(403).json({ 
        error: 'Forbidden',
        message: 'You can only delete your own avatar' 
      });
    }
    
    const profile = await UserProfile.findOne({ userId });
    
    if (!profile) {
      return res.status(404).json({ 
        error: 'Profile not found' 
      });
    }
    
    if (!profile.avatarUrl) {
      return res.status(404).json({ 
        error: 'No avatar to delete' 
      });
    }
    
    // Delete avatar file
    const avatarPath = path.join(__dirname, '..', profile.avatarUrl);
    await deleteImage(avatarPath);
    
    // Update profile
    profile.avatarUrl = null;
    await profile.save();
    
    res.json({
      message: 'Avatar deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting avatar:', error);
    res.status(500).json({ 
      error: 'Server error',
      message: error.message 
    });
  }
});

// Search users
router.get('/search', async (req, res) => {
  try {
    const { q, limit = 10 } = req.query;
    
    if (!q || q.trim().length < 2) {
      return res.status(400).json({ 
        error: 'Invalid search query',
        message: 'Query must be at least 2 characters' 
      });
    }
    
    const searchRegex = new RegExp(q.trim(), 'i');
    
    const profiles = await UserProfile.find({
      $or: [
        { username: searchRegex },
        { displayName: searchRegex }
      ]
    })
    .select('userId username displayName avatarUrl level experience')
    .limit(parseInt(limit))
    .lean();
    
    res.json({
      query: q,
      users: profiles,
      results: profiles, // Keep for backward compatibility
      total: profiles.length,
      count: profiles.length
    });
  } catch (error) {
    console.error('Error searching users:', error);
    res.status(500).json({ 
      error: 'Server error',
      message: error.message 
    });
  }
});

// Get leaderboard
router.get('/leaderboard', async (req, res) => {
  try {
    const { limit = 10, sortBy = 'experience' } = req.query;
    
    let sortField = {};
    if (sortBy === 'level') {
      sortField = { level: -1, experience: -1 };
    } else if (sortBy === 'points') {
      sortField = { 'stats.totalPoints': -1 };
    } else {
      sortField = { experience: -1 };
    }
    
    const leaderboard = await UserProfile.find()
      .select('userId username displayName avatarUrl level experience stats')
      .sort(sortField)
      .limit(parseInt(limit))
      .lean();
    
    // Add rank
    const rankedLeaderboard = leaderboard.map((profile, index) => ({
      rank: index + 1,
      userId: profile.userId,
      username: profile.username,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      level: profile.level,
      experience: profile.experience,
      stats: profile.stats
    }));
    
    res.json({
      leaderboard: rankedLeaderboard,
      count: rankedLeaderboard.length,
      sortBy
    });
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(500).json({ 
      error: 'Server error',
      message: error.message 
    });
  }
});

module.exports = router;
