# Frontend Configuration Guide

## Environment Setup

The frontend uses environment variables to configure API and Socket.io connections. This allows flexible deployment and mobile device access.

### Configuration Files

**`.env` file** (located in `frontend/.env`):
```properties
PORT=3006
REACT_APP_API_URL=http://localhost:3000
REACT_APP_SOCKET_URL=http://localhost:3003
```

### Local Development (Same Computer)

Default configuration works out of the box:
- Frontend: `http://localhost:3006`
- API Gateway: `http://localhost:3000`
- Game Socket: `http://localhost:3003`

### Mobile Device Access (Same WiFi Network)

To allow mobile devices to connect to your game:

1. **Find your computer's IP address:**
   - Windows: Run `ipconfig` in PowerShell, look for IPv4 Address (e.g., `192.168.1.100`)
   - Mac/Linux: Run `ifconfig` or `ip addr show`

2. **Update `.env` file:**
   ```properties
   PORT=3006
   REACT_APP_API_URL=http://192.168.1.100:3000
   REACT_APP_SOCKET_URL=http://192.168.1.100:3003
   ```
   Replace `192.168.1.100` with your actual IP address.

3. **Restart the frontend:**
   ```bash
   cd frontend
   npm start
   ```

4. **Access from mobile:**
   - Open browser on phone
   - Navigate to: `http://192.168.1.100:3006`
   - Join game as normal!

### Important Notes

- ✅ **All hardcoded URLs removed** - Everything uses environment variables
- ✅ **Centralized configuration** - All API URLs managed in `src/config/api.js`
- ✅ **Socket.io configuration** - Includes reconnection logic for better stability
- 🔒 **Firewall** - Make sure Windows Firewall allows connections on ports 3000, 3003, 3006
- 📱 **Same Network** - Mobile device and computer must be on the same WiFi network

### Architecture

```
frontend/
├── .env                    # Environment variables (PORT, API URLs)
├── src/
│   ├── config/
│   │   └── api.js         # Centralized API configuration
│   └── pages/
│       ├── Login.js       # Uses API_URLS.LOGIN
│       ├── Register.js    # Uses API_URLS.REGISTER
│       ├── Dashboard.js   # Uses API_URLS.QUIZZES, API_URLS.GAMES
│       ├── Join.js        # Uses API_URLS.GAME_BY_PIN, SOCKET_CONFIG
│       └── ...            # All pages updated
```

### API Configuration (`src/config/api.js`)

```javascript
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000';
const SOCKET_URL = process.env.REACT_APP_SOCKET_URL || 'http://localhost:3003';

export const API_URLS = {
  // Auth
  LOGIN: `${API_BASE_URL}/api/auth/login`,
  REGISTER: `${API_BASE_URL}/api/auth/register`,
  
  // Quiz
  QUIZZES: `${API_BASE_URL}/api/quiz/quizzes`,
  QUIZ_BY_ID: (id) => `${API_BASE_URL}/api/quiz/quizzes/${id}`,
  
  // Game
  GAMES: `${API_BASE_URL}/api/game/games`,
  GAME_BY_PIN: (pin) => `${API_BASE_URL}/api/game/games/pin/${pin}`,
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
```

### Updated Files

All files now import and use centralized configuration:

✅ **Auth Pages:**
- `Login.js` - Uses `API_URLS.LOGIN`
- `Register.js` - Uses `API_URLS.REGISTER`
- `VerifyOTP.js` - Uses `API_URLS.VERIFY_OTP`, `API_URLS.RESEND_OTP`

✅ **Quiz Pages:**
- `Dashboard.js` - Uses `API_URLS.QUIZZES`, `API_URLS.QUIZ_STAR`, `API_URLS.GAMES`
- `QuizBuilder.js` - Uses `API_URLS.QUIZ_BY_ID`, `API_URLS.QUIZZES`

✅ **Game Pages:**
- `Join.js` - Uses `API_URLS.GAME_BY_PIN`, `SOCKET_CONFIG.URL`
- `LobbyHost.js` - Uses `API_URLS.GAME_BY_PIN`, `API_URLS.QUIZ_BY_ID`, `SOCKET_CONFIG.URL`
- `LobbyPlayer.js` - Uses `SOCKET_CONFIG.URL`
- `LiveControl.js` - Uses `API_URLS.GAME_BY_PIN`, `API_URLS.QUIZ_BY_ID`, `SOCKET_CONFIG.URL`
- `Answering.js` - Uses `SOCKET_CONFIG.URL`
- `Feedback.js` - Uses `SOCKET_CONFIG.URL`
- `EndGame.js` - Uses `API_URLS.GAME_BY_PIN`
- `EndGameNew.js` - Uses `API_URLS.GAME_BY_PIN`

### Troubleshooting

**Problem:** Mobile device can't connect

**Solutions:**
1. Check both devices are on same WiFi network
2. Verify IP address is correct (use `ipconfig` on Windows)
3. Check Windows Firewall allows ports 3000, 3003, 3005
4. Try disabling firewall temporarily to test
5. Make sure backend services are running

**Problem:** "Network error" on mobile

**Solutions:**
1. Verify `.env` file has correct IP address
2. Restart frontend after changing `.env`
3. Clear browser cache on mobile device
4. Check backend logs for connection errors

### Production Deployment

For production, update `.env` with your production URLs:

```properties
PORT=3005
REACT_APP_API_URL=https://api.yourdomain.com
REACT_APP_SOCKET_URL=https://socket.yourdomain.com
```

Then build:
```bash
npm run build
```

The build will use the environment variables from `.env` file.
