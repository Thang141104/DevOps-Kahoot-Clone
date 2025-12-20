# Setup Guide for Kahoot Clone DevOps Lab

## Prerequisites

Before running this project, ensure you have:
- Docker & Docker Compose
- Kubernetes cluster with kubectl configured
- Terraform v1.5+
- Ansible v2.10+
- Node.js 18+ and npm
- AWS CLI configured with appropriate credentials
- Git

## Environment Setup

### 1. Create Environment Files

Copy the `.env.example` files to `.env` in each service directory and update with your actual values:

```bash
# Gateway
cp gateway/.env.example gateway/.env

# Services
cp services/auth-service/.env.example services/auth-service/.env
cp services/user-service/.env.example services/user-service/.env
cp services/quiz-service/.env.example services/quiz-service/.env
cp services/game-service/.env.example services/game-service/.env
cp services/analytics-service/.env.example services/analytics-service/.env
```

### 2. MongoDB Setup

This project uses MongoDB. You can:

**Option A: MongoDB Atlas Cloud (Recommended)**
1. Create account at https://www.mongodb.com/cloud/atlas
2. Create a new cluster
3. Get connection string: `mongodb+srv://username:password@cluster.mongodb.net/database`
4. Update `MONGODB_URI` in all `.env` files

**Option B: Local MongoDB**
```bash
docker run -d -p 27017:27017 -e MONGO_INITDB_ROOT_USERNAME=root \
  -e MONGO_INITDB_ROOT_PASSWORD=password \
  mongo:latest
```

Update `MONGODB_URI` to: `mongodb://root:password@localhost:27017/kahoot?authSource=admin`

### 3. Email Configuration (for Auth Service)

For email notifications in auth service:

1. Enable 2-Factor Authentication in Gmail
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Update in `services/auth-service/.env`:
   ```
   EMAIL_HOST=smtp.gmail.com
   EMAIL_PORT=587
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASSWORD=your-app-password
   ```

### 4. JWT Secret

Generate a strong JWT secret:

```bash
openssl rand -base64 32
```

Update `JWT_SECRET` in `services/auth-service/.env` and `services/user-service/.env` to the **same value**.

## Infrastructure Deployment

### Terraform (AWS Infrastructure)

```bash
cd infrastructure/terraform

# Initialize
terraform init

# Review changes
terraform plan

# Deploy
terraform apply

# Save outputs
terraform output -json > deployment-outputs.json
```

**Key Resources Created:**
- VPC with public/private subnets
- EC2 instances (Jenkins, K8s master/workers)
- Security Groups
- S3 bucket for Nx cache
- ECR repositories

### Kubernetes Deployment

```bash
cd infrastructure/ansible

# Update inventory with your EC2 IPs
vim inventory/hosts

# Deploy cluster
ansible-playbook -i inventory/hosts playbooks/deploy-kubernetes.yml

# Deploy SonarQube
ansible-playbook -i inventory/hosts playbooks/deploy-sonarqube.yml
```

## Application Deployment

### Local Development

```bash
npm install

# Terminal 1: Start all services
npm run dev

# Terminal 2: Start frontend
cd frontend
npm start
```

### Docker Deployment

```bash
docker-compose up -d
```

### Kubernetes Deployment

```bash
# Build and push images to ECR
npm run build
npm run docker:build
npm run docker:push

# Deploy to Kubernetes
kubectl apply -f k8s/
```

## Jenkins CI/CD

### Initial Setup

1. Access Jenkins: http://your-jenkins-ip:8080
2. Complete initial setup with admin password
3. Install suggested plugins

### Configure Credentials

In Jenkins Dashboard → Manage Credentials:

1. **GitHub PAT**: Create Personal Access Token on GitHub
   - Scope: `repo`, `admin:repo_hook`, `admin:org_hook`
   - Store in Jenkins as Secret text credential named `github-credentials`

2. **SonarQube Token**: Generate in SonarQube → Administration → Security → Tokens
   - Store in Jenkins as Secret text credential named `sonarqube-token`

3. **Docker Registry**: Configure for AWS ECR
   ```bash
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
   ```

### Create Pipeline Job

1. New Item → Pipeline
2. Name: `kahoot-devops-pipeline`
3. Pipeline → Definition: Pipeline script from SCM
4. SCM: Git
5. Repository URL: Your GitHub repo
6. Credentials: Select github-credentials
7. Branch: `*/main`

### GitHub Webhook

1. Go to GitHub repository Settings → Webhooks
2. Add webhook:
   - Payload URL: `http://your-jenkins-ip:8080/github-webhook/`
   - Content type: `application/json`
   - Event: Push events
   - Active: ✓

## Security

**⚠️ IMPORTANT - Before Pushing to GitHub:**

1. ✅ All `.env` files are in `.gitignore` - they will NOT be committed
2. ✅ SSH keys (`.pem`, `.key`) are in `.gitignore`
3. ✅ Terraform state files are in `.gitignore`
4. ✅ Secrets files are in `.gitignore`
5. Create `.env` files locally from `.env.example` templates
6. Never commit actual credentials

**Create a `.env.local` file for sensitive overrides:**
```bash
# .env.local (NOT committed to Git)
MONGODB_URI=your-real-connection-string
API_KEY=your-real-api-key
```

## Useful Commands

### Kubernetes

```bash
# View cluster status
kubectl get nodes
kubectl get pods -A

# View SonarQube
kubectl logs -n sonarqube deployment/sonarqube

# Port forward to SonarQube
kubectl port-forward -n sonarqube svc/sonarqube 9000:9000
```

### Nx Monorepo

```bash
# View dependency graph
npx nx graph

# Test all affected projects
npx nx affected --target=test

# Build all affected projects
npx nx affected --target=build

# Deploy to K8s
npx nx affected --target=deploy-k8s
```

### Docker

```bash
# Build all services
npm run docker:build

# Push to ECR
npm run docker:push

# Clean up images
docker system prune -a
```

### Terraform

```bash
# Destroy infrastructure
terraform destroy

# Import existing resources
terraform import aws_instance.example i-1234567890abcdef0
```

## Troubleshooting

### MongoDB Connection Issues

```bash
# Test connection
npm run test-db-connection

# Check connection string format
# Atlas: mongodb+srv://user:pass@cluster.mongodb.net/dbname
# Local: mongodb://user:pass@localhost:27017/dbname
```

### Kubernetes Pod Issues

```bash
# View pod logs
kubectl logs -n sonarqube pod/sonarqube-xxxxx

# Describe pod for events
kubectl describe pod -n sonarqube sonarqube-xxxxx

# Access pod shell
kubectl exec -it -n sonarqube sonarqube-xxxxx -- /bin/bash
```

### Jenkins Build Issues

```bash
# Check Jenkins logs
tail -f /var/log/jenkins/jenkins.log

# Restart Jenkins
systemctl restart jenkins

# Check disk space
df -h
```

## Further Documentation

- [Architecture Overview](./ARCHITECTURE.md)
- [API Documentation](./API_TESTING.md)
- [Kubernetes Guide](./k8s/README.md)
- [Terraform Configuration](./infrastructure/terraform/README.md)
- [Jenkins Pipeline](./JENKINS_CICD_README.md)
- [Security Guidelines](./SECURITY.md)

## Support

For issues or questions:
1. Check existing documentation
2. Review application logs
3. Check cloud infrastructure (AWS console)
4. Review Kubernetes cluster status
