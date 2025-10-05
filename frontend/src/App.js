import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Home from './pages/Home';
import Login from './pages/Login';
import Register from './pages/Register';
import VerifyOTP from './pages/VerifyOTP';
import Dashboard from './pages/Dashboard';
import QuizBuilder from './pages/QuizBuilder';
import Join from './pages/Join';
import LobbyHost from './pages/LobbyHost';
import LobbyPlayer from './pages/LobbyPlayer';
import LiveControl from './pages/LiveControl';
import Answering from './pages/Answering';
import Feedback from './pages/Feedback';
import Leaderboard from './pages/Leaderboard';
import EndGame from './pages/EndGame';
import Result from './pages/Result';
import './App.css';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/verify-otp" element={<VerifyOTP />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/quiz/builder/:id?" element={<QuizBuilder />} />
          <Route path="/join" element={<Join />} />
          <Route path="/lobby/host/:pin" element={<LobbyHost />} />
          <Route path="/lobby/player/:pin" element={<LobbyPlayer />} />
          <Route path="/live/control/:pin" element={<LiveControl />} />
          <Route path="/live/answer/:pin" element={<Answering />} />
          <Route path="/live/feedback/:pin" element={<Feedback />} />
          <Route path="/live/leaderboard/:pin" element={<Leaderboard />} />
          <Route path="/game/end/:pin" element={<EndGame />} />
          <Route path="/result/:sessionId" element={<Result />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
