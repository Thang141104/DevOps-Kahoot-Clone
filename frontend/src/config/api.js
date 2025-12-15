// API Configuration
// Sử dụng runtime config từ window._env_ (generated at container startup)
// Nếu không có, fallback về process.env (build time)
// Cuối cùng fallback về localhost

const API_BASE_URL = (window._env_ && window._env_.REACT_APP_API_URL) 
  || process.env.REACT_APP_API_URL 
  || 'http://localhost:3000';
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
  
  // User Service
  USER_PROFILE: (userId) => `${API_BASE_URL}/api/user/users/${userId}/profile`,
  USER_PROFILE_UPDATE: (userId) => `${API_BASE_URL}/api/user/users/${userId}/profile`,
  USER_STATS: (userId) => `${API_BASE_URL}/api/user/users/${userId}/stats`,
  USER_STATS_SYNC: (userId) => `${API_BASE_URL}/api/user/users/${userId}/stats/sync`,
  USER_ACHIEVEMENTS: (userId) => `${API_BASE_URL}/api/user/users/${userId}/achievements`,
  USER_ACTIVITY: (userId) => `${API_BASE_URL}/api/user/users/${userId}/activity`,
  USER_AVATAR: (userId) => `${API_BASE_URL}/api/user/users/${userId}/avatar`,
  USER_PREFERENCES: (userId) => `${API_BASE_URL}/api/user/users/${userId}/preferences`,
  USER_SEARCH: (query) => `${API_BASE_URL}/api/user/users/search?q=${query}`,
  USER_LEADERBOARD: `${API_BASE_URL}/api/user/users/leaderboard`,
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
