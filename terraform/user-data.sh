#!/bin/bash

# Update system
echo "=== Updating system packages ==="
apt-get update -y
apt-get upgrade -y

# Install required packages
echo "=== Installing required packages ==="
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    software-properties-common

# Install Docker
echo "=== Installing Docker ==="
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Install Docker Compose
echo "=== Installing Docker Compose ==="
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create docker group and add ubuntu user
usermod -aG docker ubuntu

# Create application directory
echo "=== Setting up application directory ==="
mkdir -p /home/ubuntu/app
cd /home/ubuntu/app

# Clone repository
echo "=== Cloning repository ==="
git clone -b ${github_branch} ${github_repo} .

# Create .env files for services
echo "=== Creating environment files ==="

# Gateway .env
cat > /home/ubuntu/app/gateway/.env << 'EOF'
PORT=3000
NODE_ENV=production
AUTH_SERVICE_URL=http://auth-service:3001
QUIZ_SERVICE_URL=http://quiz-service:3002
GAME_SERVICE_URL=http://game-service:3003
USER_SERVICE_URL=http://user-service:3004
ANALYTICS_SERVICE_URL=http://analytics-service:3005
EOF

# Auth Service .env
cat > /home/ubuntu/app/services/auth-service/.env << 'EOF'
PORT=3001
NODE_ENV=production
MONGODB_URI=${mongodb_uri}
JWT_SECRET=${jwt_secret}
JWT_EXPIRES_IN=7d
EMAIL_USER=${email_user}
EMAIL_PASSWORD=${email_password}
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
OTP_EXPIRES_IN=10
EOF

# Quiz Service .env
cat > /home/ubuntu/app/services/quiz-service/.env << 'EOF'
PORT=3002
NODE_ENV=production
MONGODB_URI=${mongodb_uri}
JWT_SECRET=${jwt_secret}
EOF

# Game Service .env
cat > /home/ubuntu/app/services/game-service/.env << 'EOF'
PORT=3003
NODE_ENV=production
MONGODB_URI=${mongodb_uri}
ANALYTICS_SERVICE_URL=http://analytics-service:3005
EOF

# User Service .env
cat > /home/ubuntu/app/services/user-service/.env << 'EOF'
PORT=3004
NODE_ENV=production
MONGODB_URI=${mongodb_uri}
JWT_SECRET=${jwt_secret}
EOF

# Analytics Service .env
cat > /home/ubuntu/app/services/analytics-service/.env << 'EOF'
PORT=3005
NODE_ENV=production
MONGODB_URI=${mongodb_uri}
EOF

# Frontend .env
cat > /home/ubuntu/app/frontend/.env << EOF
PORT=3006
REACT_APP_API_URL=http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000
REACT_APP_SOCKET_URL=http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3003
EOF

# Create Docker Compose file
echo "=== Creating Docker Compose file ==="
cat > /home/ubuntu/app/docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'

services:
  gateway:
    build: ./gateway
    container_name: kahoot-gateway
    ports:
      - "3000:3000"
    env_file:
      - ./gateway/.env
    restart: unless-stopped
    networks:
      - kahoot-network
    depends_on:
      - auth-service
      - quiz-service
      - game-service
      - user-service
      - analytics-service

  auth-service:
    build: ./services/auth-service
    container_name: kahoot-auth-service
    ports:
      - "3001:3001"
    env_file:
      - ./services/auth-service/.env
    restart: unless-stopped
    networks:
      - kahoot-network

  quiz-service:
    build: ./services/quiz-service
    container_name: kahoot-quiz-service
    ports:
      - "3002:3002"
    env_file:
      - ./services/quiz-service/.env
    restart: unless-stopped
    networks:
      - kahoot-network

  game-service:
    build: ./services/game-service
    container_name: kahoot-game-service
    ports:
      - "3003:3003"
    env_file:
      - ./services/game-service/.env
    restart: unless-stopped
    networks:
      - kahoot-network

  user-service:
    build: ./services/user-service
    container_name: kahoot-user-service
    ports:
      - "3004:3004"
    env_file:
      - ./services/user-service/.env
    restart: unless-stopped
    networks:
      - kahoot-network

  analytics-service:
    build: ./services/analytics-service
    container_name: kahoot-analytics-service
    ports:
      - "3005:3005"
    env_file:
      - ./services/analytics-service/.env
    restart: unless-stopped
    networks:
      - kahoot-network

  frontend:
    build: ./frontend
    container_name: kahoot-frontend
    ports:
      - "3006:3006"
      - "80:3006"
    env_file:
      - ./frontend/.env
    restart: unless-stopped
    networks:
      - kahoot-network
    depends_on:
      - gateway

networks:
  kahoot-network:
    driver: bridge
COMPOSE_EOF

# Set proper ownership
chown -R ubuntu:ubuntu /home/ubuntu/app

# Build and start services
echo "=== Building and starting Docker containers ==="
cd /home/ubuntu/app
docker-compose up -d --build

# Wait for services to be ready
echo "=== Waiting for services to start ==="
sleep 30

# Show status
echo "=== Docker container status ==="
docker-compose ps

# Show logs
echo "=== Recent logs ==="
docker-compose logs --tail=50

echo "=== Deployment completed successfully ==="
echo "=== Application is running on: ==="
echo "    - Frontend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3006"
echo "    - API Gateway: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
