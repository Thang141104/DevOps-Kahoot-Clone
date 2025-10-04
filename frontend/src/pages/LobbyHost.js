import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { FiUsers, FiPlay } from 'react-icons/fi';
import './LobbyHost.css';

const LobbyHost = () => {
  const { pin } = useParams();
  const navigate = useNavigate();
  const [players, setPlayers] = useState([
    { id: 1, name: 'Thu Ngân', avatar: '#E5164F' },
    { id: 2, name: 'Văn Tài', avatar: '#26890D' },
    { id: 3, name: 'Hoài Phú', avatar: '#9B51E0' },
    { id: 4, name: 'Hữu Thắng', avatar: '#FFC107' },
    { id: 5, name: 'Hoàng Phúc', avatar: '#1368CE' },
    { id: 6, name: 'Minh Lộc', avatar: '#F97316' }
  ]);

  const [quizTitle] = useState('General Knowledge — NeLe Demo');

  const startGame = () => {
    navigate(`/live/control/${pin}`);
  };

  return (
    <div className="lobby-container">
      <div className="lobby-content">
        <h1 className="quiz-title">{quizTitle}</h1>
        <p className="lobby-subtitle">Players are joining...</p>

        <div className="lobby-grid">
          <div className="pin-card">
            <h3>GAME PIN</h3>
            <div className="pin-display">{pin}</div>
            <button className="btn-show-qr">
              <span>📱</span> Show QR Code
            </button>
            <p className="join-instruction">Join at nele.app</p>
          </div>

          <div className="players-card">
            <div className="players-header">
              <FiUsers size={24} />
              <h3>{players.length} Players</h3>
              <button className="btn-sound">🔊</button>
            </div>

            <div className="players-grid">
              {players.map(player => (
                <div key={player.id} className="player-badge">
                  <div 
                    className="player-avatar"
                    style={{ backgroundColor: player.avatar }}
                  >
                    {player.name.charAt(0)}
                  </div>
                  <span className="player-name">{player.name}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        <button className="btn-start-game" onClick={startGame}>
          <FiPlay /> Start Game
        </button>

        <p className="ready-text">Ready to start with {players.length} players</p>

        <div className="loading-indicator">
          <span className="dot"></span>
          <span className="dot"></span>
          <span className="dot"></span>
        </div>
      </div>
    </div>
  );
};

export default LobbyHost;
