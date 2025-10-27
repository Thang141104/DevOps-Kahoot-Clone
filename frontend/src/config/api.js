// API Configuration
// Sử dụng environment variables từ .env file
// Nếu không có trong .env, fallback về localhost

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000';
const SOCKET_URL = process.env.REACT_APP_SOCKET_URL || 'http://localhost:3003';

export const API_URLS = {
  // Auth Service
  LOGIN: `${API_BASE_URL}/api/auth/login`,
  REGISTER: `${API_BASE_URL}/api/auth/register`,
  VERIFY_OTP: `${API_BASE_URL}/api/auth/verify-otp`,
  RESEND_OTP: `${API_BASE_URL}/api/auth/resend-otp`,
  
  // Quiz Service
  QUIZZES: `${API_BASE_URL}/api/quiz/quizzes`,
  QUIZ_BY_ID: (id) => `${API_BASE_URL}/api/quiz/quizzes/${id}`,
  QUIZ_STAR: (id) => `${API_BASE_URL}/api/quiz/quizzes/${id}/star`,
  QUIZ_DELETE: (id) => `${API_BASE_URL}/api/quiz/quizzes/${id}`,
  
  // Game Service
  GAMES: `${API_BASE_URL}/api/game/games`,
  GAME_BY_PIN: (pin) => `${API_BASE_URL}/api/game/games/pin/${pin}`,
  GAME_BY_ID: (id) => `${API_BASE_URL}/api/game/games/${id}`,
  GAME_DELETE: (id) => `${API_BASE_URL}/api/game/games/${id}`,
};

export const SOCKET_CONFIG = {
  URL: SOCKET_URL,
  OPTIONS: {
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 5000,
    reconnectionAttempts: 5
  }
};

export default API_URLS;
