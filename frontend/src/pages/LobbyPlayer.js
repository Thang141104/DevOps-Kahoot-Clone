import React from 'react';
import { useParams } from 'react-router-dom';
import './LobbyPlayer.css';

const LobbyPlayer = () => {
  const { pin } = useParams();

  return (
    <div className="lobby-player-container">
      <div className="lobby-player-content">
        <div className="connected-icon">
          <span>⚡</span>
        </div>

        <h1 className="status-title">You're In!</h1>
        <p className="status-subtitle">Waiting for the game to start...</p>

        <div className="pin-display-card">
          <div className="avatar-circle" style={{ backgroundColor: '#E5164F' }}>
            ?
          </div>
          <p className="pin-label">PIN</p>
          <h2 className="pin-number">{pin}</h2>

          <div className="players-joined">
            <div className="avatar-group">
              <span className="mini-avatar" style={{ backgroundColor: '#E5164F' }}>?</span>
              <span className="mini-avatar" style={{ backgroundColor: '#FFC107' }}>?</span>
              <span className="mini-avatar" style={{ backgroundColor: '#26890D' }}>?</span>
              <span className="mini-avatar" style={{ backgroundColor: '#1368CE' }}>?</span>
              <span className="mini-avatar" style={{ backgroundColor: '#9B51E0' }}>?</span>
              <span className="mini-avatar" style={{ backgroundColor: '#F97316' }}>?</span>
            </div>
            <p>6 players joined</p>
          </div>
        </div>

        <p className="ready-text">Get ready to show what you know!</p>

        <div className="loading-dots">
          <span className="dot"></span>
          <span className="dot"></span>
          <span className="dot"></span>
        </div>
      </div>
    </div>
  );
};

export default LobbyPlayer;
