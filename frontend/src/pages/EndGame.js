import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import './EndGame.css';

const EndGame = () => {
  const { pin } = useParams();
  const navigate = useNavigate();

  const [results] = React.useState({
    rank: 2,
    score: 2750,
    accuracy: 100,
    correctAnswers: 3,
    totalQuestions: 3,
    achievements: ['Fastest Answer', 'Perfect Score', 'Speed Demon']
  });

  return (
    <div className="endgame-container">
      <div className="endgame-content">
        <div className="trophy-icon">🏆</div>
        
        <h1 className="endgame-title">Great Job!</h1>
        <p className="endgame-subtitle">You made it to the top 3!</p>

        <div className="result-card">
          <div className="player-badge">
            <div className="player-avatar" style={{ backgroundColor: '#26890D' }}>
              V
            </div>
            <h2 className="player-name">Văn Tài</h2>
            <div className="final-rank">
              #{results.rank} <span>out of 6</span>
            </div>
          </div>

          <div className="stats-section">
            <div className="stat-row">
              <span className="stat-label">Final Score</span>
              <h3 className="stat-value">{results.score}</h3>
            </div>

            <div className="stat-grid">
              <div className="stat-item">
                <span className="stat-icon">🎯</span>
                <span className="stat-label">Accuracy</span>
                <span className="stat-value">{results.accuracy}%</span>
              </div>
              <div className="stat-item">
                <span className="stat-icon">✅</span>
                <span className="stat-label">Correct</span>
                <span className="stat-value">{results.correctAnswers}/{results.totalQuestions}</span>
              </div>
            </div>
          </div>

          <div className="achievements-section">
            <h4>🏅 Achievements</h4>
            <div className="achievements-grid">
              {results.achievements.map((achievement, index) => (
                <div key={index} className="achievement-badge">
                  {achievement}
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="loading-dots">
          <span className="dot"></span>
          <span className="dot"></span>
          <span className="dot"></span>
        </div>

        <p className="waiting-text">Waiting for other players to finish...</p>
      </div>
    </div>
  );
};

export default EndGame;
