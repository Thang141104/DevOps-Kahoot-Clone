import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiArrowLeft, FiSave, FiPlus, FiTrash2, FiImage } from 'react-icons/fi';
import './QuizBuilder.css';

const QuizBuilder = () => {
  const navigate = useNavigate();
  const [quiz, setQuiz] = useState({
    title: 'General Knowledge — NeLe Demo',
    description: '',
    visibility: 'Public',
    language: 'English'
  });

  const [questions, setQuestions] = useState([
    {
      id: 1,
      type: 'Single Choice',
      title: 'Capital of Vietnam?',
      timeLimit: 20,
      points: 1000,
      options: ['Hanoi', 'Ho Chi Minh City', 'Da Nang', 'Hue'],
      correctAnswer: 0,
      media: null
    },
    {
      id: 2,
      type: 'True/False',
      title: '7 is a prime number',
      timeLimit: 15,
      points: 800,
      options: ['True', 'False'],
      correctAnswer: 0,
      media: null
    },
    {
      id: 3,
      type: 'Multiple Choice',
      title: 'Pick prime numbers',
      timeLimit: 25,
      points: 1200,
      options: ['2', '3', '4', '5'],
      correctAnswer: [0, 1, 3],
      media: null
    }
  ]);

  const [selectedQuestion, setSelectedQuestion] = useState(0);

  const addQuestion = () => {
    const newQuestion = {
      id: questions.length + 1,
      type: 'Single Choice',
      title: '',
      timeLimit: 20,
      points: 1000,
      options: ['', '', '', ''],
      correctAnswer: 0,
      media: null
    };
    setQuestions([...questions, newQuestion]);
    setSelectedQuestion(questions.length);
  };

  const updateQuestion = (field, value) => {
    const updated = [...questions];
    updated[selectedQuestion] = {
      ...updated[selectedQuestion],
      [field]: value
    };
    setQuestions(updated);
  };

  const deleteQuestion = (index) => {
    const updated = questions.filter((_, i) => i !== index);
    setQuestions(updated);
    if (selectedQuestion >= updated.length) {
      setSelectedQuestion(Math.max(0, updated.length - 1));
    }
  };

  const updateOption = (optionIndex, value) => {
    const updated = [...questions];
    updated[selectedQuestion].options[optionIndex] = value;
    setQuestions(updated);
  };

  const addOption = () => {
    const updated = [...questions];
    updated[selectedQuestion].options.push('');
    setQuestions(updated);
  };

  const currentQ = questions[selectedQuestion];

  return (
    <div className="quiz-builder-container">
      <header className="builder-header">
        <button className="btn-back" onClick={() => navigate('/dashboard')}>
          <FiArrowLeft /> Back
        </button>
        <div className="header-title">
          <h2>{quiz.title}</h2>
          <span className="question-count">{questions.length} questions</span>
        </div>
        <button className="btn-save">
          <FiSave /> Save Quiz
        </button>
      </header>

      <div className="builder-layout">
        <aside className="quiz-settings">
          <h3>Quiz Settings</h3>
          
          <div className="form-group">
            <label>Quiz Title</label>
            <input
              type="text"
              value={quiz.title}
              onChange={(e) => setQuiz({...quiz, title: e.target.value})}
              placeholder="Enter quiz title"
            />
          </div>

          <div className="form-group">
            <label>Description</label>
            <textarea
              value={quiz.description}
              onChange={(e) => setQuiz({...quiz, description: e.target.value})}
              placeholder="Add a description..."
              rows="3"
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Visibility</label>
              <select 
                value={quiz.visibility}
                onChange={(e) => setQuiz({...quiz, visibility: e.target.value})}
              >
                <option>Public</option>
                <option>Private</option>
              </select>
            </div>

            <div className="form-group">
              <label>Language</label>
              <select 
                value={quiz.language}
                onChange={(e) => setQuiz({...quiz, language: e.target.value})}
              >
                <option>English</option>
                <option>Vietnamese</option>
              </select>
            </div>
          </div>

          <div className="questions-list">
            <h4>Questions</h4>
            {questions.map((q, index) => (
              <div 
                key={q.id}
                className={`question-item ${index === selectedQuestion ? 'active' : ''}`}
                onClick={() => setSelectedQuestion(index)}
              >
                <div className="question-info">
                  <span className="question-label">Q{index + 1}</span>
                  <span className="question-type">{q.type}</span>
                </div>
                <div className="question-meta">
                  <span>{q.timeLimit}s</span>
                  <span>{q.points} pts</span>
                  <span>{q.options.length} options</span>
                </div>
                <button 
                  className="btn-delete-question"
                  onClick={(e) => {
                    e.stopPropagation();
                    deleteQuestion(index);
                  }}
                >
                  <FiTrash2 />
                </button>
              </div>
            ))}
            <button className="btn-add-question" onClick={addQuestion}>
              <FiPlus /> Add Question
            </button>
          </div>
        </aside>

        <main className="question-editor">
          <h3>Question Editor</h3>
          
          {currentQ && (
            <>
              <div className="form-group">
                <label>Question Title</label>
                <input
                  type="text"
                  value={currentQ.title}
                  onChange={(e) => updateQuestion('title', e.target.value)}
                  placeholder="Enter your question"
                />
              </div>

              <div className="form-group">
                <label>Question Type</label>
                <select 
                  value={currentQ.type}
                  onChange={(e) => updateQuestion('type', e.target.value)}
                >
                  <option>Single Choice</option>
                  <option>Multiple Choice</option>
                  <option>True/False</option>
                </select>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Time Limit (seconds)</label>
                  <input
                    type="number"
                    value={currentQ.timeLimit}
                    onChange={(e) => updateQuestion('timeLimit', parseInt(e.target.value))}
                    min="5"
                    max="120"
                  />
                </div>

                <div className="form-group">
                  <label>Points</label>
                  <input
                    type="number"
                    value={currentQ.points}
                    onChange={(e) => updateQuestion('points', parseInt(e.target.value))}
                    min="100"
                    max="5000"
                    step="100"
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Media</label>
                <div className="media-upload">
                  <FiImage size={32} />
                  <p>Click to upload image or video</p>
                  <span>PNG, JPG, MP4, up to 10MB</span>
                </div>
              </div>

              <div className="form-group">
                <label>Answer Options</label>
                <div className="options-list">
                  {currentQ.options.map((option, index) => (
                    <div key={index} className="option-item">
                      <input
                        type={currentQ.type === 'Multiple Choice' ? 'checkbox' : 'radio'}
                        name="correct-answer"
                        checked={
                          Array.isArray(currentQ.correctAnswer) 
                            ? currentQ.correctAnswer.includes(index)
                            : currentQ.correctAnswer === index
                        }
                        onChange={() => {
                          if (currentQ.type === 'Multiple Choice') {
                            const current = Array.isArray(currentQ.correctAnswer) ? currentQ.correctAnswer : [];
                            const updated = current.includes(index)
                              ? current.filter(i => i !== index)
                              : [...current, index];
                            updateQuestion('correctAnswer', updated);
                          } else {
                            updateQuestion('correctAnswer', index);
                          }
                        }}
                      />
                      <input
                        type="text"
                        value={option}
                        onChange={(e) => updateOption(index, e.target.value)}
                        placeholder={`Option ${index + 1}`}
                      />
                      {currentQ.options.length > 2 && (
                        <button 
                          className="btn-delete-option"
                          onClick={() => {
                            const updated = [...questions];
                            updated[selectedQuestion].options = updated[selectedQuestion].options.filter((_, i) => i !== index);
                            setQuestions(updated);
                          }}
                        >
                          <FiTrash2 />
                        </button>
                      )}
                    </div>
                  ))}
                  {currentQ.options.length < 6 && (
                    <button className="btn-add-option" onClick={addOption}>
                      <FiPlus /> Add Option
                    </button>
                  )}
                </div>
              </div>

              <div className="form-group">
                <label>
                  <input type="checkbox" />
                  Shuffle answer options
                </label>
              </div>
            </>
          )}
        </main>
      </div>
    </div>
  );
};

export default QuizBuilder;
