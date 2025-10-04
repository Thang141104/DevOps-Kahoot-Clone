import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiStar, FiPlus, FiTrendingUp, FiUsers, FiTarget } from 'react-icons/fi';
import './Dashboard.css';

const Dashboard = () => {
  const navigate = useNavigate();
  const [quizzes, setQuizzes] = useState([
    {
      id: 1,
      title: 'General Knowledge — NeLe Demo',
      questions: 3,
      plays: 45,
      accuracy: 78,
      lastPlayed: '2 hours ago',
      starred: true
    },
    {
      id: 2,
      title: 'Mathematics Challenge',
      questions: 10,
      plays: 23,
      accuracy: 65,
      lastPlayed: '1 day ago',
      starred: false
    },
    {
      id: 3,
      title: 'Science Quiz',
      questions: 8,
      plays: 67,
      accuracy: 82,
      lastPlayed: '3 days ago',
      starred: true
    }
  ]);

  const [filter, setFilter] = useState('all');
  const [stats] = useState({
    totalPlays: 135,
    avgAccuracy: 75,
    starredQuizzes: 2
  });

  const filteredQuizzes = quizzes.filter(quiz => {
    if (filter === 'starred') return quiz.starred;
    if (filter === 'recent') return true; // Would sort by date
    return true;
  });

  const toggleStar = (id) => {
    setQuizzes(quizzes.map(q => 
      q.id === id ? { ...q, starred: !q.starred } : q
    ));
  };

  return (
    <div className="dashboard-container">
      <header className="dashboard-header">
        <div className="logo">
          <span className="logo-icon">N</span>
          <span className="logo-text">NeLe</span>
        </div>
        <button className="btn-new-quiz" onClick={() => navigate('/quiz/builder')}>
          <FiPlus /> New Quiz
        </button>
      </header>

      <div className="dashboard-content">
        <div className="page-title">
          <h1>Your Quizzes</h1>
          <p>Create, manage, and track your interactive quizzes</p>
        </div>

        <div className="stats-grid">
          <div className="stat-card">
            <div className="stat-icon" style={{backgroundColor: '#FFE5E5'}}>
              <FiTrendingUp color="#E5164F" size={24} />
            </div>
            <div className="stat-info">
              <h3>{stats.totalPlays}</h3>
              <p>Total Plays</p>
            </div>
          </div>

          <div className="stat-card">
            <div className="stat-icon" style={{backgroundColor: '#E5F9E5'}}>
              <FiTarget color="#26890D" size={24} />
            </div>
            <div className="stat-info">
              <h3>{stats.avgAccuracy}%</h3>
              <p>Avg Accuracy</p>
            </div>
          </div>

          <div className="stat-card">
            <div className="stat-icon" style={{backgroundColor: '#FFF9E5'}}>
              <FiStar color="#FFC107" size={24} />
            </div>
            <div className="stat-info">
              <h3>{stats.starredQuizzes}</h3>
              <p>Starred Quizzes</p>
            </div>
          </div>
        </div>

        <div className="quizzes-section">
          <div className="section-header">
            <input 
              type="text" 
              placeholder="Search quizzes..." 
              className="search-input"
            />
            <div className="filter-tabs">
              <button 
                className={filter === 'all' ? 'active' : ''}
                onClick={() => setFilter('all')}
              >
                All
              </button>
              <button 
                className={filter === 'starred' ? 'active' : ''}
                onClick={() => setFilter('starred')}
              >
                <FiStar /> Starred
              </button>
              <button 
                className={filter === 'recent' ? 'active' : ''}
                onClick={() => setFilter('recent')}
              >
                Recent
              </button>
            </div>
          </div>

          <div className="quizzes-grid">
            {filteredQuizzes.map(quiz => (
              <div key={quiz.id} className="quiz-card">
                <div className="quiz-header">
                  <div className="quiz-badge">
                    {quiz.questions} questions
                  </div>
                  <button 
                    className={`star-btn ${quiz.starred ? 'starred' : ''}`}
                    onClick={() => toggleStar(quiz.id)}
                  >
                    <FiStar />
                  </button>
                </div>
                <h3 className="quiz-title">{quiz.title}</h3>
                <div className="quiz-stats">
                  <div className="quiz-stat-item">
                    <span className="stat-label">Plays</span>
                    <span className="stat-value">{quiz.plays}</span>
                  </div>
                  <div className="quiz-stat-item">
                    <span className="stat-label">Avg Accuracy</span>
                    <span className="stat-value">{quiz.accuracy}%</span>
                  </div>
                </div>
                <div className="quiz-footer">
                  <span className="last-played">Last played {quiz.lastPlayed}</span>
                </div>
              </div>
            ))}

            <div className="quiz-card create-new" onClick={() => navigate('/quiz/builder')}>
              <div className="create-icon">
                <FiPlus size={40} />
              </div>
              <h3>Create New Quiz</h3>
              <p>Start from scratch</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
