import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiStar, FiPlus, FiTrendingUp, FiUsers, FiTarget, FiPlay, FiEdit, FiTrash2 } from 'react-icons/fi';
import API_URLS from '../config/api';
import './Dashboard.css';

const Dashboard = () => {
  const navigate = useNavigate();
  const [quizzes, setQuizzes] = useState([]);
  const [filter, setFilter] = useState('all');
  const [stats, setStats] = useState({
    totalPlays: 0,
    avgAccuracy: 0,
    starredQuizzes: 0
  });
  const [loading, setLoading] = useState(true);

  // Fetch quizzes on mount
  useEffect(() => {
    fetchQuizzes();
  }, [filter]);

  const fetchQuizzes = async () => {
    try {
      // Check if user is logged in
      const user = JSON.parse(localStorage.getItem('user'));
      if (!user || !user.id) {
        navigate('/login');
        return;
      }

      // Fetch user's quizzes
      const url = filter === 'starred' 
        ? `${API_URLS.QUIZZES}?userId=${user.id}&filter=starred`
        : `${API_URLS.QUIZZES}?userId=${user.id}`;

      const response = await fetch(url);
      const data = await response.json();

      if (response.ok) {
        setQuizzes(data);
        
        // Calculate stats
        const totalPlays = data.reduce((sum, q) => sum + (q.stats?.totalPlays || 0), 0);
        const avgAcc = data.reduce((sum, q) => sum + (q.stats?.avgAccuracy || 0), 0) / (data.length || 1);
        const starred = data.filter(q => q.starred).length;
        
        setStats({
          totalPlays,
          avgAccuracy: Math.round(avgAcc),
          starredQuizzes: starred
        });
      } else {
        console.error('Failed to fetch quizzes:', data);
      }
    } catch (error) {
      console.error('Error fetching quizzes:', error);
    } finally {
      setLoading(false);
    }
  };

  const toggleStar = async (id) => {
    try {
      const response = await fetch(API_URLS.QUIZ_STAR(id), {
        method: 'PATCH'
      });

      if (response.ok) {
        // Update local state
        setQuizzes(quizzes.map(q => 
          q._id === id ? { ...q, starred: !q.starred } : q
        ));
      }
    } catch (error) {
      console.error('Error toggling star:', error);
    }
  };

  const handleDeleteQuiz = async (id, quizTitle) => {
    // Confirmation dialog
    if (!window.confirm(`Are you sure you want to delete "${quizTitle}"?\n\nThis action cannot be undone.`)) {
      return;
    }

    try {
      const response = await fetch(API_URLS.QUIZ_DELETE(id), {
        method: 'DELETE'
      });

      if (response.ok) {
        // Remove from local state
        setQuizzes(quizzes.filter(q => q._id !== id));
        alert('Quiz deleted successfully!');
      } else {
        const data = await response.json();
        alert('Failed to delete quiz: ' + (data.message || 'Unknown error'));
      }
    } catch (error) {
      console.error('Error deleting quiz:', error);
      alert('Error deleting quiz. Please try again.');
    }
  };

  const handleStartGame = async (quizId) => {
    try {
      // Get logged-in user
      const user = JSON.parse(localStorage.getItem('user'));
      if (!user || !user.id) {
        alert('Please login to start a game');
        navigate('/login');
        return;
      }

      console.log('🎮 Creating game for quiz:', quizId, 'host:', user.id);

      // Create game session
      const response = await fetch(API_URLS.GAMES, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          quizId: quizId,
          hostId: user.id
        })
      });

      const data = await response.json();
      console.log('Game creation response:', data);

      if (response.ok) {
        console.log('✅ Game created with PIN:', data.pin);
        // Navigate to lobby with PIN
        navigate(`/lobby/host/${data.pin}`);
      } else {
        console.error('❌ Failed to create game:', data.error);
        alert('Failed to create game: ' + (data.error || 'Unknown error'));
      }
    } catch (error) {
      console.error('Error creating game:', error);
      alert('Error creating game. Please try again.');
    }
  };

  const filteredQuizzes = quizzes;

  return (
    <div className="dashboard-container">
      <header className="dashboard-header">
        <div className="logo">
          <span className="logo-icon">N</span>
          <span className="logo-text">NeLe</span>
        </div>
        <div className="header-actions">
          <button className="btn-game-history" onClick={() => navigate('/game/history')}>
            <FiPlay /> Game History
          </button>
          <button className="btn-new-quiz" onClick={() => navigate('/quiz/builder')}>
            <FiPlus /> New Quiz
          </button>
        </div>
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
            {loading ? (
              <p>Loading quizzes...</p>
            ) : filteredQuizzes.length === 0 ? (
              <div style={{textAlign: 'center', padding: '40px'}}>
                <p>No quizzes found. Create your first quiz!</p>
                <button className="btn-new-quiz" onClick={() => navigate('/quiz/builder')}>
                  <FiPlus /> Create Quiz
                </button>
              </div>
            ) : (
              filteredQuizzes.map(quiz => (
                <div key={quiz._id} className="quiz-card">
                  <div className="quiz-header">
                    <div className="quiz-badge">
                      {quiz.questions?.length || 0} questions
                    </div>
                    <button 
                      className={`star-btn ${quiz.starred ? 'starred' : ''}`}
                      onClick={() => toggleStar(quiz._id)}
                    >
                      <FiStar />
                    </button>
                  </div>
                  <h3 className="quiz-title">{quiz.title}</h3>
                  <div className="quiz-stats">
                    <div className="quiz-stat-item">
                      <span className="stat-label">Plays</span>
                      <span className="stat-value">{quiz.stats?.totalPlays || 0}</span>
                    </div>
                    <div className="quiz-stat-item">
                      <span className="stat-label">Avg Accuracy</span>
                      <span className="stat-value">{quiz.stats?.avgAccuracy || 0}%</span>
                    </div>
                  </div>
                  <div className="quiz-footer">
                    <span className="last-played">
                      Created {new Date(quiz.createdAt).toLocaleDateString()}
                    </span>
                    <div className="quiz-actions">
                      <button 
                        className="btn-edit-quiz"
                        onClick={() => navigate(`/quiz/builder/${quiz._id}`)}
                        title="Edit Quiz"
                      >
                        <FiEdit />
                      </button>
                      <button 
                        className="btn-delete-quiz"
                        onClick={() => handleDeleteQuiz(quiz._id, quiz.title)}
                        title="Delete Quiz"
                      >
                        <FiTrash2 />
                      </button>
                      <button 
                        className="btn-start-game"
                        onClick={() => handleStartGame(quiz._id)}
                      >
                        <FiPlay /> Start
                      </button>
                    </div>
                  </div>
                </div>
              ))
            )}

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
