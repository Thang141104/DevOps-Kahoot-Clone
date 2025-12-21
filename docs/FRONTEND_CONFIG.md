# Frontend Configuration Guide

This guide explains how to configure the React frontend application for different deployment scenarios.

## Environment Variables

The frontend uses environment variables to configure API endpoints and service URLs. These are loaded at build time.

### Configuration File

Create or edit `frontend/.env`:

```properties
# Development Port
PORT=3001

# API Gateway URL
REACT_APP_API_URL=http://localhost:3000

# Game Service Socket.io URL  
REACT_APP_SOCKET_URL=http://localhost:3004

# Enable debug mode (optional)
REACT_APP_DEBUG=false
```

## Deployment Scenarios

### 1. Local Development (localhost)

**Use case**: Development on your local machine

```properties
PORT=3001
REACT_APP_API_URL=http://localhost:3000
REACT_APP_SOCKET_URL=http://localhost:3004
```

**Access**: http://localhost:3001

### 2. LAN Access (Mobile Devices)

**Use case**: Testing on mobile devices connected to same WiFi

**Step 1**: Find your computer's IP address

**Windows**:
```powershell
ipconfig
# Look for "IPv4 Address" under your active adapter
# Example: 192.168.1.100
```

**macOS/Linux**:
```bash
ifconfig
# or
ip addr show
# Look for inet address on active interface
```

**Step 2**: Update `.env` with your IP:

```properties
PORT=3001
REACT_APP_API_URL=http://192.168.1.100:3000
REACT_APP_SOCKET_URL=http://192.168.1.100:3004
```

**Step 3**: Restart frontend:

```bash
cd frontend
npm start
```

**Step 4**: Access from mobile browser:
- URL: `http://192.168.1.100:3001`
- Make sure firewall allows connections

### 3. Kubernetes Production Deployment

**Use case**: Production deployment in K8s cluster

```properties
# These are set automatically by Kubernetes ConfigMap
REACT_APP_API_URL=http://<master-node-ip>:30000
REACT_APP_SOCKET_URL=http://<master-node-ip>:30004
```

Configuration is managed through `k8s/base/configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: kahoot-clone
data:
  GATEWAY_URL: "http://gateway:3000"
  GAME_SERVICE_URL: "http://game-service:3004"
```

Frontend Dockerfile includes build-time variable injection:

```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
ARG REACT_APP_API_URL
ARG REACT_APP_SOCKET_URL
ENV REACT_APP_API_URL=$REACT_APP_API_URL
ENV REACT_APP_SOCKET_URL=$REACT_APP_SOCKET_URL
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## API Configuration

The frontend uses a centralized API configuration file: `src/config/api.js`

```javascript
const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000';
const SOCKET_URL = process.env.REACT_APP_SOCKET_URL || 'http://localhost:3004';

export const API_ENDPOINTS = {
  // Auth endpoints
  LOGIN: `${API_URL}/api/auth/login`,
  REGISTER: `${API_URL}/api/auth/register`,
  VERIFY_OTP: `${API_URL}/api/auth/verify-otp`,
  
  // User endpoints
  USER_PROFILE: (userId) => `${API_URL}/api/users/profile/${userId}`,
  USER_AVATAR: (userId) => `${API_URL}/api/users/profile/${userId}/avatar`,
  
  // Quiz endpoints
  QUIZZES: `${API_URL}/api/quizzes`,
  QUIZ_DETAIL: (quizId) => `${API_URL}/api/quizzes/${quizId}`,
  
  // Game endpoints  
  CREATE_GAME: `${API_URL}/api/games/create`,
  JOIN_GAME: `${API_URL}/api/games/join`,
  
  // Analytics
  LEADERBOARD: `${API_URL}/api/analytics/leaderboard`,
  GAME_HISTORY: `${API_URL}/api/analytics/history`
};

export const SOCKET_CONFIG = {
  url: SOCKET_URL,
  options: {
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 5000,
    reconnectionAttempts: 5,
    transports: ['websocket', 'polling']
  }
};

export default { API_ENDPOINTS, SOCKET_CONFIG };
```

## Socket.io Configuration

Game service uses Socket.io for real-time communication.

### Client Configuration

In `src/pages/Game.js` or similar:

```javascript
import io from 'socket.io-client';
import { SOCKET_CONFIG } from '../config/api';

// Initialize socket connection
const socket = io(SOCKET_CONFIG.url, SOCKET_CONFIG.options);

// Connection events
socket.on('connect', () => {
  console.log('Connected to game server');
});

socket.on('disconnect', () => {
  console.log('Disconnected from game server');
});

// Game events
socket.on('player-joined', (data) => {
  console.log('Player joined:', data);
});

socket.on('question-start', (data) => {
  console.log('Question started:', data);
});
```

### CORS Configuration

Ensure backend allows frontend origin in `services/game-service/server.js`:

```javascript
const io = require('socket.io')(server, {
  cors: {
    origin: process.env.FRONTEND_URL || 'http://localhost:3001',
    methods: ['GET', 'POST'],
    credentials: true
  }
});
```

## Build and Deployment

### Development Build

```bash
cd frontend
npm install
npm start
# Runs on PORT from .env (default: 3001)
```

### Production Build

```bash
cd frontend
npm install
npm run build
# Creates optimized build in build/ directory
```

### Docker Build

```bash
# Build image
docker build -t kahoot-frontend:latest \
  --build-arg REACT_APP_API_URL=http://gateway:3000 \
  --build-arg REACT_APP_SOCKET_URL=http://game-service:3004 \
  frontend/

# Run container
docker run -p 80:80 kahoot-frontend:latest
```

### Kubernetes Deployment

Frontend is deployed via `k8s/frontend/frontend-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: kahoot-clone
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: <ecr-registry>/kahoot-clone-frontend:latest
        ports:
        - containerPort: 80
        env:
        - name: REACT_APP_API_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: GATEWAY_URL
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: kahoot-clone
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30001
  selector:
    app: frontend
```

## Troubleshooting

### Issue: API calls fail with CORS error

**Solution**:
- Verify `REACT_APP_API_URL` matches gateway URL
- Check gateway CORS configuration allows frontend origin
- Ensure both frontend and gateway are accessible

### Issue: Socket.io connection fails

**Solution**:
```javascript
// Enable debug logging
const socket = io(SOCKET_CONFIG.url, {
  ...SOCKET_CONFIG.options,
  debug: true
});

// Check connection status
socket.on('connect_error', (error) => {
  console.error('Connection error:', error);
});
```

- Verify `REACT_APP_SOCKET_URL` points to game service
- Check game service is running and accessible
- Ensure firewall/security groups allow WebSocket connections

### Issue: Mobile device cannot connect

**Solution**:
- Verify computer and mobile are on same WiFi network
- Check firewall allows incoming connections on required ports
- Use computer's actual IP (not localhost)
- Test API connectivity: `http://<ip>:3000/health`

### Issue: Environment variables not updating

**Solution**:
- Environment variables are baked into build at compile time
- After changing `.env`, restart dev server:
  ```bash
  # Stop (Ctrl+C)
  npm start
  ```
- For production, rebuild image:
  ```bash
  docker build --no-cache ...
  ```

## Best Practices

1. **Never commit `.env` files**: Use `.env.example` as template
2. **Use environment-specific configs**: Separate dev/staging/prod
3. **Validate URLs**: Ensure no trailing slashes in API_URL
4. **Enable HTTPS in production**: Use TLS certificates
5. **Implement retry logic**: Handle network failures gracefully
6. **Cache API responses**: Reduce redundant requests
7. **Use relative paths**: For internal routing within app

## References

- [Create React App Environment Variables](https://create-react-app.dev/docs/adding-custom-environment-variables/)
- [Socket.io Client API](https://socket.io/docs/v4/client-api/)
- [Axios Documentation](https://axios-http.com/docs/intro)

---

Last Updated: December 2025
