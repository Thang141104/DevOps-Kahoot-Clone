# Environment Variables Automation Guide

## 🎯 Mục Tiêu

Đảm bảo environment variables **GIỐNG HỆT NHAU** giữa:
- Docker Compose deployment (App Server)
- Kubernetes deployment (K8s Cluster)

## 🔄 Luồng Tự Động

### 1. **Terraform Variables** → Nguồn Gốc Duy Nhất (Single Source of Truth)

```hcl
# terraform/terraform.tfvars
mongodb_uri     = "mongodb+srv://..."
jwt_secret      = "your-secret-key"
email_user      = "your-email@gmail.com"
email_password  = "your-app-password"
```

### 2. **Auto-Generation Flow**

```
Terraform Variables
        ↓
    [user-data.sh]
        ↓
   ├─→ Docker Compose .env files (7 services)
   │   ├─ gateway/.env
   │   ├─ services/auth-service/.env
   │   ├─ services/quiz-service/.env
   │   ├─ services/game-service/.env
   │   ├─ services/user-service/.env
   │   ├─ services/analytics-service/.env
   │   └─ frontend/.env
   │
   └─→ Kubernetes secrets.yaml
       └─ k8s/secrets.yaml (auto-generated)
```

## 📋 Environment Variables Mapping

### Docker Compose .env Files

#### Gateway (`gateway/.env`)
```bash
PORT=3000
NODE_ENV=production
AUTH_SERVICE_URL=http://auth-service:3001
QUIZ_SERVICE_URL=http://quiz-service:3002
GAME_SERVICE_URL=http://game-service:3003
USER_SERVICE_URL=http://user-service:3004
ANALYTICS_SERVICE_URL=http://analytics-service:3005
```

#### Auth Service (`services/auth-service/.env`)
```bash
PORT=3001
NODE_ENV=production
MONGODB_URI=${mongodb_uri}          # ← From Terraform
JWT_SECRET=${jwt_secret}            # ← From Terraform
JWT_EXPIRES_IN=7d
EMAIL_USER=${email_user}            # ← From Terraform
EMAIL_PASSWORD=${email_password}    # ← From Terraform
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
OTP_EXPIRES_IN=10
```

#### Quiz Service (`services/quiz-service/.env`)
```bash
PORT=3002
NODE_ENV=production
MONGODB_URI=${mongodb_uri}          # ← From Terraform
JWT_SECRET=${jwt_secret}            # ← From Terraform
```

#### Game Service (`services/game-service/.env`)
```bash
PORT=3003
NODE_ENV=production
MONGODB_URI=${mongodb_uri}          # ← From Terraform
ANALYTICS_SERVICE_URL=http://analytics-service:3005
```

#### User Service (`services/user-service/.env`)
```bash
PORT=3004
NODE_ENV=production
MONGODB_URI=${mongodb_uri}          # ← From Terraform
JWT_SECRET=${jwt_secret}            # ← From Terraform
```

#### Analytics Service (`services/analytics-service/.env`)
```bash
PORT=3005
NODE_ENV=production
MONGODB_URI=${mongodb_uri}          # ← From Terraform
```

#### Frontend (`frontend/.env`)
```bash
PORT=3006
REACT_APP_API_URL=http://<PUBLIC_IP>:3000
REACT_APP_SOCKET_URL=http://<PUBLIC_IP>:3003
```

### Kubernetes Resources

#### ConfigMap (`k8s/configmap.yaml`) - Non-Sensitive Data
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: kahoot-clone
data:
  NODE_ENV: "production"
  
  # Service URLs (K8s DNS)
  AUTH_SERVICE_URL: "http://auth-service:3001"
  QUIZ_SERVICE_URL: "http://quiz-service:3002"
  GAME_SERVICE_URL: "http://game-service:3003"
  USER_SERVICE_URL: "http://user-service:3004"
  ANALYTICS_SERVICE_URL: "http://analytics-service:3005"
  
  # Ports
  GATEWAY_PORT: "3000"
  AUTH_PORT: "3001"
  QUIZ_PORT: "3002"
  GAME_PORT: "3003"
  USER_PORT: "3004"
  ANALYTICS_PORT: "3005"
  FRONTEND_PORT: "3006"
  
  # Email Server
  EMAIL_HOST: "smtp.gmail.com"
  EMAIL_PORT: "587"
  
  # Other
  JWT_EXPIRES_IN: "7d"
  OTP_EXPIRES_IN: "10"
  CORS_ORIGIN: "*"
```

#### Secrets (`k8s/secrets.yaml`) - Sensitive Data (Auto-Generated)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: kahoot-clone
type: Opaque
stringData:
  MONGODB_URI: "${mongodb_uri}"      # ← From Terraform
  JWT_SECRET: "${jwt_secret}"        # ← From Terraform
  EMAIL_USER: "${email_user}"        # ← From Terraform
  EMAIL_PASSWORD: "${email_password}" # ← From Terraform
  EMAIL_HOST: "smtp.gmail.com"
  EMAIL_PORT: "587"
  SESSION_SECRET: "${jwt_secret}"
  OTP_EXPIRES_IN: "10"
```

## 🔐 Security Best Practices

### ✅ DO:
- Store secrets in Terraform variables
- Use `.gitignore` for `terraform.tfvars` and `.env` files
- Auto-generate K8s secrets from Terraform
- Use K8s Secrets for sensitive data
- Use ConfigMap for non-sensitive config

### ❌ DON'T:
- Commit `secrets.yaml` to Git
- Hardcode secrets in code
- Mix secrets and config
- Share `.env` files publicly

## 🛠️ Validation

### Run Validation Script
```bash
cd /path/to/repo
chmod +x scripts/validate-env-vars.sh
./scripts/validate-env-vars.sh
```

### Expected Output:
```
🔍 Validating Environment Variables Consistency...
==================================================

📦 Docker Compose Environment Variables:
----------------------------------------
  gateway:
    PORT=3000
    NODE_ENV=production
    ...

☸️  Kubernetes Environment Variables:
----------------------------------------
  ConfigMap (app-config):
    NODE_ENV: "production"
    GATEWAY_PORT: "3000"
    ...
  
  Secrets (app-secrets):
    MONGODB_URI: ***REDACTED***
    JWT_SECRET: ***REDACTED***
    ...

✅ Critical Variables Validation:
----------------------------------------
  ✓ MONGODB_URI: Present in both K8s and Docker Compose
  ✓ JWT_SECRET: Present in both K8s and Docker Compose
  ✓ EMAIL_USER: Present in both K8s and Docker Compose
  ✓ EMAIL_PASSWORD: Present in both K8s and Docker Compose
  ✓ NODE_ENV: Present in both K8s and Docker Compose
```

## 🚀 Deployment Workflow

### Terraform Apply (First Time)
```bash
cd terraform
terraform apply

# This automatically:
# 1. Creates EC2 instances
# 2. Runs user-data.sh
# 3. Generates .env files for Docker Compose
# 4. Generates k8s/secrets.yaml
# 5. Starts Docker Compose on App Server
```

### Jenkins Pipeline
```bash
# Pipeline automatically:
# 1. Builds Docker images
# 2. Pushes to Docker Hub
# 3. Applies k8s/configmap.yaml
# 4. Applies k8s/secrets.yaml (generated from Terraform)
# 5. Deploys to K8s cluster
```

### Manual K8s Deployment
```bash
# SSH to K8s master
ssh -i kahoot-key.pem ubuntu@<k8s-ip>

# Clone repo (secrets.yaml already generated by Terraform)
cd DevOps-Kahoot-Clone

# Apply
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml  # ← Auto-generated
kubectl apply -f k8s/

# Verify
kubectl get pods -n kahoot-clone
kubectl get configmap -n kahoot-clone
kubectl get secrets -n kahoot-clone
```

## 🔍 Troubleshooting

### Issue: Pods showing ImagePullBackOff
```bash
# Check if images exist
docker pull 22521284/kahoot-clone-gateway:latest

# Verify deployment uses correct registry
kubectl describe deployment gateway -n kahoot-clone | grep Image
```

### Issue: Pods showing CrashLoopBackOff
```bash
# Check pod logs
kubectl logs -f <pod-name> -n kahoot-clone

# Common causes:
# - Missing env vars
# - Wrong MongoDB URI
# - Invalid JWT secret
```

### Issue: Environment variables not matching
```bash
# Run validation script
./scripts/validate-env-vars.sh

# Check K8s secrets
kubectl get secret app-secrets -n kahoot-clone -o yaml

# Check ConfigMap
kubectl get configmap app-config -n kahoot-clone -o yaml
```

## 📊 Comparison Table

| Aspect | Docker Compose | Kubernetes |
|--------|----------------|------------|
| **Source** | Terraform vars → .env files | Terraform vars → secrets.yaml |
| **Config Method** | `env_file: .env` | ConfigMap + Secrets |
| **Secrets Storage** | Plain text .env | Base64 encoded Secrets |
| **Auto-Sync** | ✅ Via user-data.sh | ✅ Via user-data.sh |
| **Updates** | Restart containers | Rolling updates |
| **Validation** | Manual file check | `kubectl describe` |

## ✅ Checklist

- [ ] Terraform variables set in `terraform.tfvars`
- [ ] `.gitignore` includes `.env` and `terraform.tfvars`
- [ ] `secrets.yaml.example` committed (template only)
- [ ] `secrets.yaml` NOT committed (auto-generated)
- [ ] Validation script runs successfully
- [ ] All 7 services have matching env vars
- [ ] MongoDB connection works in both environments
- [ ] Email service configured correctly

---

**Last Updated**: December 14, 2025  
**Commit**: 1356960 - Auto-generate K8s secrets from Terraform
