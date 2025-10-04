import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { FiDownload, FiRotateCcw, FiHome } from 'react-icons/fi';
import './Result.css';

const Result = () => {
  const { sessionId } = useParams();
  const navigate = useNavigate();

  const [results] = React.useState({
    quizTitle: 'General Knowledge — NeLe Demo',
    completedAt: new Date(),
    totalPlayers: 6,
    topPlayers: [
      { rank: 1, name: 'Thu Ngân', score: 2950, accuracy: 100, avgTime: '8.2s', avatar: '#E5164F' },
      { rank: 2, name: 'Văn Tài', score: 2750, accuracy: 100, avgTime: '9.5s', avatar: '#26890D' },
      { rank: 3, name: 'Hữu Thắng', score: 2400, accuracy: 67, avgTime: '12.1s', avatar: '#FFC107' },
      { rank: 4, name: 'Hoài Phú', score: 2200, accuracy: 67, avgTime: '11.5s', avatar: '#9B51E0' },
      { rank: 5, name: 'Hoàng Phúc', score: 2000, accuracy: 67, avgTime: '14.5s', avatar: '#1368CE' },
      { rank: 6, name: 'Minh Lộc', score: 1800, accuracy: 67, avgTime: '15.2s', avatar: '#F97316' }
    ],
    questionAnalysis: [
      { id: 1, title: 'Capital of Vietnam?', accuracy: 85, avgTime: '9.2s' },
      { id: 2, title: '7 is a prime number', accuracy: 95, avgTime: '7.8s' },
      { id: 3, title: 'Pick prime numbers', accuracy: 60, avgTime: '14.5s' }
    ]
  });

  return (
    <div className="result-container">
      <header className="result-header">
        <div className="header-content">
          <div className="session-badge">
            <span className="trophy-icon">🎖️</span>
            <span>Session Results</span>
          </div>
          <h1>{results.quizTitle}</h1>
          <p>{results.totalPlayers} players completed the quiz</p>
        </div>

        <div className="action-buttons">
          <button className="btn-action" onClick={() => navigate('/dashboard')}>
            <FiHome /> Back to Dashboard
          </button>
          <button className="btn-action">
            <FiRotateCcw /> Play Again
          </button>
          <button className="btn-action btn-primary">
            <FiDownload /> Export Results
          </button>
        </div>
      </header>

      <div className="result-content">
        <section className="congratulations-section">
          <div className="confetti-bg">
            <h2>Congratulations!</h2>
            <p>6 players completed the quiz</p>
          </div>

          <div className="action-cards">
            <button className="action-card">
              <FiRotateCcw size={24} />
              <h3>Play Again</h3>
            </button>
            <button className="action-card yellow">
              <span style={{ fontSize: '24px' }}>📝</span>
              <h3>Review Questions</h3>
            </button>
            <button className="action-card">
              <FiDownload size={24} />
              <h3>Export Results</h3>
            </button>
          </div>
        </section>

        <section className="podium-section">
          <h2>🏆 Top 3 Players</h2>
          <div className="podium">
            {results.topPlayers.slice(0, 3).map((player, index) => (
              <div key={player.rank} className={`podium-place place-${player.rank}`}>
                <div className="podium-avatar" style={{ backgroundColor: player.avatar }}>
                  {player.name.charAt(0)}
                </div>
                <div className="medal">{index === 0 ? '🥇' : index === 1 ? '🥈' : '🥉'}</div>
                <h3>{player.name}</h3>
                <div className="podium-score">{player.score}</div>
                <div className="podium-stats">
                  <span>{player.accuracy}% Accuracy</span>
                  <span>{player.avgTime} Avg Time</span>
                </div>
              </div>
            ))}
          </div>
        </section>

        <section className="leaderboard-section">
          <h2>📊 Full Leaderboard</h2>
          <div className="leaderboard-table">
            <div className="table-header">
              <span>Rank</span>
              <span>Player</span>
              <span>Score</span>
              <span>Accuracy</span>
              <span>Avg Time</span>
            </div>
            {results.topPlayers.map(player => (
              <div key={player.rank} className={`table-row ${player.rank <= 3 ? 'highlight' : ''}`}>
                <span className="rank-cell">{player.rank}</span>
                <span className="player-cell">
                  <div className="player-avatar-small" style={{ backgroundColor: player.avatar }}>
                    {player.name.charAt(0)}
                  </div>
                  {player.name}
                </span>
                <span className="score-cell">{player.score}</span>
                <span className="accuracy-cell">
                  <span className="accuracy-badge">{player.accuracy}%</span>
                </span>
                <span className="time-cell">{player.avgTime}</span>
              </div>
            ))}
          </div>
        </section>

        <section className="question-analysis-section">
          <h2>📈 Question Analysis</h2>
          <div className="analysis-grid">
            {results.questionAnalysis.map(question => (
              <div key={question.id} className="analysis-card">
                <div className="question-number">Q{question.id}</div>
                <h3>{question.title}</h3>
                <div className="analysis-stats">
                  <div className="stat">
                    <span className="stat-label">Accuracy</span>
                    <span className="stat-value">{question.accuracy}%</span>
                  </div>
                  <div className="stat">
                    <span className="stat-label">Avg Time</span>
                    <span className="stat-value">{question.avgTime}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
};

export default Result;
