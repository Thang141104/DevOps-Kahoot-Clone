import React from 'react';
import { useParams } from 'react-router-dom';
import './Feedback.css';

const Feedback = () => {
  const { pin } = useParams();
  const [feedback] = React.useState({
    isCorrect: true,
    points: 1000,
    streak: 3
  });

  return (
    <div className={`feedback-container ${feedback.isCorrect ? 'correct' : 'incorrect'}`}>
      <div className="feedback-content">
        <div className="feedback-icon">
          {feedback.isCorrect ? '✓' : '✗'}
        </div>

        <h1 className="feedback-title">
          {feedback.isCorrect ? 'Correct!' : 'Incorrect!'}
        </h1>

        <div className="points-card">
          <p className="points-label">Points Earned</p>
          <h2 className="points-value">+{feedback.points}</h2>
        </div>

        {feedback.isCorrect && feedback.streak >= 3 && (
          <div className="streak-badge">
            <span className="streak-icon">⚡</span>
            <span className="streak-text">{feedback.streak}x Streak!</span>
            <p className="streak-subtext">You're on fire! Keep it up!</p>
          </div>
        )}

        <div className="loading-dots">
          <span className="dot"></span>
          <span className="dot"></span>
          <span className="dot"></span>
        </div>

        <p className="waiting-text">Waiting for next question...</p>
      </div>
    </div>
  );
};

export default Feedback;
