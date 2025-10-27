import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import io from 'socket.io-client';
import { SOCKET_CONFIG } from '../config/api';
import './LobbyPlayer.css';

const LobbyPlayer = () => {
  const { pin } = useParams();
  const navigate = useNavigate();
  const [socket, setSocket] = useState(null);
  const [playerName, setPlayerName] = useState('');
  const [playerColor, setPlayerColor] = useState('');

  useEffect(() => {
    // Get player data from localStorage (set when joining)
    const storedPlayer = JSON.parse(localStorage.getItem('currentPlayer') || '{}');
    setPlayerName(storedPlayer.nickname || 'Player');
    setPlayerColor(storedPlayer.color || '#E5164F');

    // Reuse existing socket or create new one
    let newSocket = window.gameSocket;
    
    if (!newSocket || !newSocket.connected) {
      console.log('🔌 Creating new socket connection...');
      newSocket = io(SOCKET_CONFIG.URL);
      window.gameSocket = newSocket;
      
      // Re-join room if needed (for refresh case)
      newSocket.on('connect', () => {
        console.log('🔌 Reconnecting to room:', pin);
        newSocket.emit('join-game', {
          pin,
          player: storedPlayer
        });
      });
    } else {
      console.log('🔌 Reusing existing socket connection');
    }
    
    setSocket(newSocket);

    // Listen for game start
    newSocket.on('game-started', ({ game }) => {
      console.log('🎮 Game started! Navigating to answering page...');
      navigate(`/live/answer/${pin}`);
    });

    // Handle errors
    newSocket.on('error', (error) => {
      console.error('Socket error:', error);
      alert(error.message || 'An error occurred');
    });

    return () => {
      // Don't close socket - keep it alive for Answering page
      console.log('🔌 LobbyPlayer unmounting, keeping socket alive');
    };
  }, [pin, navigate]);

  return (
    <div className="lobby-player-container">
      <div className="lobby-player-content">
        <div className="connected-icon">
          <span>⚡</span>
        </div>

        <h1 className="status-title">You're In!</h1>
        <p className="status-subtitle">Waiting for the game to start...</p>

        <div className="pin-display-card">
          <div className="avatar-circle" style={{ backgroundColor: playerColor }}>
            {playerName.charAt(0).toUpperCase()}
          </div>
          <p className="pin-label">PIN</p>
          <h2 className="pin-number">{pin}</h2>

          <div className="players-joined">
            <p className="player-name">{playerName}</p>
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
