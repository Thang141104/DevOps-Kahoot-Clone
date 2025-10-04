import React from 'react';
import { useParams } from 'react-router-dom';
import './Leaderboard.css';

const Leaderboard = () => {
  const { pin } = useParams();
  const [players] = React.useState([
    { id: 1, name: 'Thu Ngân', score: 2950, avatar: '#E5164F', change: 0 },
    { id: 2, name: 'Hữu Thắng', score: 2750, avatar: '#FFC107', change: 1 },
    { id: 3, name: 'Văn Tài', score: 2400, avatar: '#26890D', change: -1 },
    { id: 4, name: 'Hoài Phú', score: 2200, avatar: '#9B51E0', change: 0 },
    { id: 5, name: 'Hoàng Phúc', score: 2000, avatar: '#1368CE', change: 0 }
  ]);

  return (
    <div className="leaderboard-container">
      <div className="leaderboard-content">
        <h1 className="leaderboard-title">Leaderboard</h1>
        <p className="leaderboard-subtitle">See how you stack up!</p>

        <div className="top-player-card">
          <div className="medal-icon">🏆</div>
          <div 
            className="top-player-avatar"
            style={{ backgroundColor: players[0].avatar }}
          >
            {players[0].name.charAt(0)}
          </div>
          <h2 className="top-player-name">{players[0].name}</h2>
          <div className="top-player-rank">#1 <span className="rank-change">↑ +1</span></div>
          <div className="top-player-score-section">
            <p className="score-label">Your Score</p>
            <h3 className="score-value">{players[0].score}</h3>
          </div>
        </div>

        <div className="players-list">
          <h3 className="list-title">Top Players</h3>
          {players.map((player, index) => (
            <div key={player.id} className={`player-row ${index === 0 ? 'highlight' : ''}`}>
              <div className="player-rank-badge">{index + 1}</div>
              <div 
                className="player-avatar-small"
                style={{ backgroundColor: player.avatar }}
              >
                {player.name.charAt(0)}
              </div>
              <span className="player-name-text">{player.name}</span>
              <span className="player-score-text">{player.score}</span>
            </div>
          ))}
        </div>

        <div className="loading-dots">
          <span className="dot"></span>
          <span className="dot"></span>
          <span className="dot"></span>
        </div>

        <p className="next-question-text">Next question coming up...</p>
      </div>
    </div>
  );
};

export default Leaderboard;
