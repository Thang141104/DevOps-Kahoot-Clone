# Docker Deployment Guide

## 🐳 Quick Start with Docker Compose

### Prerequisites
- Docker Desktop installed
- MongoDB Atlas account (free tier)
- Gmail account with App Password (for OTP)

### Steps

1. **Create .env file**
   ```powershell
   cp .env.example .env
   ```

2. **Edit .env with your values**
   ```env
   MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/kahoot
   JWT_SECRET=your-random-secret-key
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASSWORD=your-app-password
   ```

3. **Build and start all services**
   ```powershell
   docker-compose up -d --build
   ```

4. **Check status**
   ```powershell
   docker-compose ps
   ```

5. **View logs**
   ```powershell
   docker-compose logs -f
   ```

6. **Access application**
   - Frontend: http://localhost:3006
   - API Gateway: http://localhost:3000

### Useful Commands

```powershell
# Stop all services
docker-compose stop

# Start all services
docker-compose start

# Restart all services
docker-compose restart

# Stop and remove containers
docker-compose down

# Stop and remove containers + volumes
docker-compose down -v

# View logs for specific service
docker-compose logs -f frontend
docker-compose logs -f gateway

# Execute command in container
docker-compose exec frontend sh
docker-compose exec gateway sh

# Rebuild specific service
docker-compose up -d --build frontend

# View resource usage
docker stats
```

## 🚀 Terraform Deployment to AWS

See [terraform/README.md](terraform/README.md) for detailed AWS deployment instructions.

### Quick Deploy
```powershell
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
./deploy.ps1
```

### Quick Destroy
```powershell
cd terraform
./destroy.ps1
```
