# 🐳 Docker Image Build Guide

## Overview

This project uses **pre-built Docker images** hosted on Docker Hub. The Kubernetes cluster pulls these images instead of building them on-demand.

## Why Pre-build?

- ✅ **Security**: No Docker Hub credentials needed in terraform.tfvars
- ✅ **Speed**: K8s deployment is faster (no build time)
- ✅ **Reliability**: Same images for all deployments
- ✅ **CI/CD Ready**: Jenkins can build and push automatically

## 🚀 Quick Start

### Option 1: Build from Local Machine (Recommended for First Time)

**Windows (PowerShell):**
```powershell
# Login to Docker Hub
docker login
# Username: 22521284
# Password: <your-docker-hub-password>

# Run build script
.\build-and-push.ps1
```

**Linux/Mac (Bash):**
```bash
# Login to Docker Hub
docker login

# Run build script
chmod +x build-and-push.sh
./build-and-push.sh
```

### Option 2: Build from K8s Master (SSH)

```bash
# SSH to K8s master
ssh -i kahoot-key.pem ubuntu@<K8S_IP>

# Login to Docker Hub
docker login

# Clone repo
git clone https://github.com/Thang141104/DevOps-Kahoot-Clone.git
cd DevOps-Kahoot-Clone

# Build and push
chmod +x build-and-push.sh
./build-and-push.sh
```

### Option 3: Use Jenkins Pipeline (Automated)

Jenkins will automatically build and push images on every commit.

## 📦 Images Built

The script builds and pushes these images to Docker Hub:

1. `22521284/kahoot-clone-auth:latest` - Authentication service
2. `22521284/kahoot-clone-user:latest` - User management service
3. `22521284/kahoot-clone-quiz:latest` - Quiz service
4. `22521284/kahoot-clone-game:latest` - Game service
5. `22521284/kahoot-clone-analytics:latest` - Analytics service
6. `22521284/kahoot-clone-gateway:latest` - API Gateway
7. `22521284/kahoot-clone-frontend:latest` - React frontend

## 🔄 Workflow

```
┌─────────────────────────────────────────────────────┐
│  1. Build Images (One-time or on code change)       │
├─────────────────────────────────────────────────────┤
│     Local Machine/Jenkins                            │
│           ↓                                          │
│     docker build + docker push                       │
│           ↓                                          │
│     Docker Hub (22521284/kahoot-clone-*)            │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  2. Deploy with Terraform (Multiple times)          │
├─────────────────────────────────────────────────────┤
│     terraform apply                                  │
│           ↓                                          │
│     K8s pulls images from Docker Hub                │
│           ↓                                          │
│     Pods running with pre-built images              │
└─────────────────────────────────────────────────────┘
```

## 🔐 Security Notes

- **Never commit** `terraform.tfvars` (contains secrets)
- **Never commit** Docker Hub password to GitHub
- Use Docker Hub Access Tokens instead of password
- Jenkins stores credentials securely

## 🛠️ Manual Build Commands

If you prefer to build manually:

```bash
# Build
docker build -t 22521284/kahoot-clone-auth:latest ./services/auth-service
docker build -t 22521284/kahoot-clone-user:latest ./services/user-service
docker build -t 22521284/kahoot-clone-quiz:latest ./services/quiz-service
docker build -t 22521284/kahoot-clone-game:latest ./services/game-service
docker build -t 22521284/kahoot-clone-analytics:latest ./services/analytics-service
docker build -t 22521284/kahoot-clone-gateway:latest ./gateway
docker build -t 22521284/kahoot-clone-frontend:latest ./frontend

# Push
docker push 22521284/kahoot-clone-auth:latest
docker push 22521284/kahoot-clone-user:latest
docker push 22521284/kahoot-clone-quiz:latest
docker push 22521284/kahoot-clone-game:latest
docker push 22521284/kahoot-clone-analytics:latest
docker push 22521284/kahoot-clone-gateway:latest
docker push 22521284/kahoot-clone-frontend:latest
```

## ✅ Verify Images on Docker Hub

Check images at: https://hub.docker.com/u/22521284

## 🔄 When to Re-build?

Re-run the build script when you:
- Change service code (Node.js files)
- Update Dockerfiles
- Modify frontend code (React)
- Update dependencies (package.json)

## 📝 Troubleshooting

**Images not pulling on K8s?**
```bash
# Check if images exist on Docker Hub
docker pull 22521284/kahoot-clone-auth:latest

# Check K8s pod events
kubectl describe pod <pod-name> -n kahoot-clone
```

**Build failed?**
- Make sure Docker Desktop is running
- Check you're logged in: `docker info | grep Username`
- Verify Dockerfiles exist in each service directory

## 🎯 Best Practices

1. **Build once** when code changes
2. **Tag versions** for production (e.g., `v1.0.0`)
3. **Use Jenkins** for automated builds
4. **Keep `latest`** tag updated
5. **Test locally** before pushing

---

**Last Updated**: December 2025  
**Docker Hub**: https://hub.docker.com/u/22521284
