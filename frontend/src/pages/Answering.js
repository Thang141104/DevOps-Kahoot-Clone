import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import './Answering.css';

const Answering = () => {
  const { pin } = useParams();
  const [timeLeft, setTimeLeft] = useState(20);
  const [selectedAnswer, setSelectedAnswer] = useState(null);
  const [question] = useState({
    number: 1,
    total: 3,
    title: 'Capital of Vietnam?',
    options: [
      { id: 'A', text: 'Hanoi', color: '#E5164F' },
      { id: 'B', text: 'Ho Chi Minh City', color: '#FFC107' },
      { id: 'C', text: 'Da Nang', color: '#26890D' },
      { id: 'D', text: 'Hue', color: '#1368CE' }
    ]
  });

  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft(prev => {
        if (prev <= 1) {
          clearInterval(timer);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  const handleAnswer = (optionId) => {
    if (!selectedAnswer) {
      setSelectedAnswer(optionId);
    }
  };

  return (
    <div className="answering-container">
      <div className="question-header">
        <span className="question-badge">Question {question.number}/{question.total}</span>
        <div className="timer-circle">
          <svg width="60" height="60">
            <circle cx="30" cy="30" r="26" fill="none" stroke="#E2E8F0" strokeWidth="4"/>
            <circle 
              cx="30" 
              cy="30" 
              r="26" 
              fill="none" 
              stroke="#26890D" 
              strokeWidth="4"
              strokeDasharray={`${(timeLeft / 20) * 163} 163`}
              transform="rotate(-90 30 30)"
            />
          </svg>
          <span className="timer-text">{timeLeft}</span>
        </div>
      </div>

      <h1 className="question-title">{question.title}</h1>

      <div className="options-grid">
        {question.options.map(option => (
          <button
            key={option.id}
            className={`answer-option ${selectedAnswer === option.id ? 'selected' : ''}`}
            style={{ backgroundColor: option.color }}
            onClick={() => handleAnswer(option.id)}
            disabled={selectedAnswer !== null}
          >
            <span className="option-label">{option.id}</span>
            <span className="option-text">{option.text}</span>
          </button>
        ))}
      </div>

      {selectedAnswer && (
        <div className="answer-submitted">
          <div className="check-icon">✓</div>
          <p>Answer submitted! Waiting for other players...</p>
        </div>
      )}
    </div>
  );
};

export default Answering;
