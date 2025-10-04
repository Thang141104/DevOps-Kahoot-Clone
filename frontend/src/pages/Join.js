import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiZap } from 'react-icons/fi';
import './Join.css';

const Join = () => {
  const navigate = useNavigate();
  const [pin, setPin] = useState('');
  const [nickname, setNickname] = useState('');
  const [selectedAvatar, setSelectedAvatar] = useState(0);

  const avatarColors = [
    '#E5164F', '#FFC107', '#26890D', '#1368CE',
    '#9B51E0', '#F97316', '#EC4899', '#06B6D4'
  ];

  const handleJoin = () => {
    if (pin && nickname) {
      navigate(`/lobby/player/${pin}`);
    }
  };

  return (
    <div className="join-container">
      <div className="join-card">
        <div className="join-icon">
          <FiZap size={32} />
        </div>
        <h1>Join Quiz</h1>
        <p>Enter the game PIN to get started</p>

        <div className="form-section">
          <div className="form-group">
            <label>Game PIN</label>
            <input
              type="text"
              value={pin}
              onChange={(e) => setPin(e.target.value)}
              placeholder="123456"
              maxLength="6"
              className="pin-input"
            />
          </div>

          <div className="form-group">
            <label>Your Nickname</label>
            <input
              type="text"
              value={nickname}
              onChange={(e) => setNickname(e.target.value)}
              placeholder="Enter your name"
              className="nickname-input"
            />
          </div>

          <div className="form-group">
            <label>Choose Your Avatar</label>
            <div className="avatar-grid">
              {avatarColors.map((color, index) => (
                <button
                  key={index}
                  className={`avatar-option ${selectedAvatar === index ? 'selected' : ''}`}
                  style={{ backgroundColor: color }}
                  onClick={() => setSelectedAvatar(index)}
                >
                  ?
                </button>
              ))}
            </div>
          </div>

          <button 
            className="btn-join-game" 
            onClick={handleJoin}
            disabled={!pin || !nickname}
          >
            <FiZap /> Join Game
          </button>
        </div>

        <p className="help-text">
          Get the PIN from your host to join the quiz
        </p>
      </div>
    </div>
  );
};

export default Join;
