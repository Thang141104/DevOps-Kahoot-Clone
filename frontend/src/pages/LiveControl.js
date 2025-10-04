import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import './LiveControl.css';

const LiveControl = () => {
  const { pin } = useParams();
  const navigate = useNavigate();
  const [currentQuestion] = React.useState({
    number: 1,
    total: 3,
    title: 'Capital of Vietnam?',
    answered: 20,
    totalPlayers: 20
  });

  const [responses] = React.useState([
    { id: 'A', text: 'Hanoi', count: 12, isCorrect: true },
    { id: 'B', text: 'Ho Chi Minh City', count: 5, isCorrect: false },
    { id: 'C', text: 'Da Nang', count: 2, isCorrect: false },
    { id: 'D', text: 'Hue', count: 1, isCorrect: false }
  ]);

  const [leaderboard] = React.useState([
    { name: 'Thu Ngân', score: 1000 },
    { name: 'Văn Tài', score: 950 },
    { name: 'Hữu Thắng', score: 900 },
    { name: 'Hoàng Phúc', score: 850 },
    { name: 'Hoài Phú', score: 800 }
  ]);

  return (
    <div className="live-control-container">
      <header className="live-header">
        <div className="header-left">
          <h2>General Knowledge — NeLe Demo</h2>
          <span className="question-progress">Question {currentQuestion.number}/{currentQuestion.total}</span>
        </div>
        <div className="header-right">
          <span className="pin-badge">📌 PIN: {pin}</span>
          <span className="players-badge">👥 {currentQuestion.totalPlayers}/20</span>
          <button className="btn-end-game" onClick={() => navigate(`/game/end/${pin}`)}>
            End Game
          </button>
        </div>
      </header>

      <div className="live-content">
        <div className="question-section">
          <div className="question-card">
            <div className="question-type-badge">Single Choice</div>
            <h1 className="question-text">{currentQuestion.title}</h1>
            <div className="media-preview">
              <span>👁️</span>
              <p>Question media preview</p>
            </div>
            <div className="progress-bar">
              <div 
                className="progress-fill"
                style={{ width: `${(currentQuestion.answered / currentQuestion.totalPlayers) * 100}%` }}
              />
            </div>
            <p className="answered-count">{currentQuestion.answered} of {currentQuestion.totalPlayers} players answered</p>
          </div>

          <div className="responses-section">
            <h3>Live Responses</h3>
            <button className="btn-show-answer">👁️ Show Answer</button>

            <div className="responses-grid">
              {responses.map(response => {
                const percentage = currentQuestion.answered > 0 
                  ? Math.round((response.count / currentQuestion.answered) * 100) 
                  : 0;
                
                return (
                  <div key={response.id} className="response-bar">
                    <div className="response-label">
                      <span className={`option-badge ${response.isCorrect ? 'correct' : ''}`}>
                        {response.id}
                      </span>
                      <span className="option-text">{response.text}</span>
                    </div>
                    <div className="response-stats">
                      <span className="response-count">{response.count}</span>
                      <div className="bar-container">
                        <div 
                          className="bar-fill"
                          style={{ width: `${percentage}%` }}
                        />
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        <aside className="leaderboard-sidebar">
          <h3>🏆 Live Leaderboard</h3>
          <div className="leaderboard-list">
            {leaderboard.map((player, index) => (
              <div key={index} className="leaderboard-item">
                <span className="rank">{index + 1}</span>
                <div className="player-info">
                  <div className="player-avatar" style={{
                    backgroundColor: ['#E5164F', '#26890D', '#FFC107', '#1368CE', '#9B51E0'][index]
                  }}>
                    {player.name.charAt(0)}
                  </div>
                  <span className="player-name">{player.name}</span>
                </div>
                <span className="player-score">{player.score}</span>
              </div>
            ))}
          </div>

          <button className="btn-next-question">
            Next Question →
          </button>
        </aside>
      </div>
    </div>
  );
};

export default LiveControl;
