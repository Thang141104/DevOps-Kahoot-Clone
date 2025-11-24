# Jenkins CI/CD Pipeline for Kahoot Clone Microservices

## 📋 Overview

This repository contains a complete CI/CD pipeline using Jenkins for the Kahoot Clone microservices application. The pipeline includes:

- ✅ Automated build and testing
- ✅ Code quality analysis with SonarQube
- ✅ Security scanning with Trivy and Snyk
- ✅ Docker image building and scanning
- ✅ Kubernetes deployment
- ✅ Infrastructure as Code with Terraform

## 🏗️ Architecture

### Infrastructure Components

1. **Jenkins Server** (EC2 t3.medium)
   - Jenkins LTS with Docker support
   - SonarQube for code quality
   - PostgreSQL for SonarQube
   - Docker Registry for private images

2. **Kubernetes Cluster** (EC2 t3.medium)
   - k3s lightweight Kubernetes
   - Namespaced deployments
   - NodePort services for external access

3. **Microservices**
   - Gateway (Port 3000)
   - Auth Service (Port 3001)
   - Quiz Service (Port 3002)
   - Game Service (Port 3003)
   - User Service (Port 3004)
   - Analytics Service (Port 3005)
   - Frontend (Port 3006)

## 🚀 Quick Start

### Prerequisites

- AWS Account with CLI configured
- Terraform installed (v1.0+)
- Git installed
- SSH key pair created in AWS

### Step 1: Update AWS Credentials

Update your AWS credentials in `terraform/terraform.tfvars`:
```
Access Key ID: YOUR_AWS_ACCESS_KEY_ID
Secret Access Key: YOUR_AWS_SECRET_ACCESS_KEY
```

⚠️ **IMPORTANT:** Never commit real credentials to git! Use the `terraform.tfvars.example` template.

### Step 2: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the infrastructure plan
terraform plan

# Deploy the infrastructure
terraform apply -auto-approve
```

This will create:
- VPC with public subnet
- Jenkins server with SonarQube
- Kubernetes (k3s) cluster
- Security groups
- Elastic IPs (optional)

### Step 3: Access Jenkins

After deployment (wait ~5 minutes for services to start):

```bash
# Get Jenkins IP
terraform output jenkins_public_ip

# Get Jenkins URL
terraform output jenkins_url

# SSH to Jenkins server to get initial password
ssh -i kahoot-key.pem ubuntu@<JENKINS_IP>
/home/ubuntu/show-info.sh
```

**Jenkins URL:** `http://<JENKINS_IP>:8080`

**Initial Admin Password:** Will be displayed in the output

### Step 4: Configure Jenkins

1. **Install Jenkins Plugins:**
   - Docker Pipeline
   - Kubernetes
   - SonarQube Scanner
   - Git
   - NodeJS
   - Blue Ocean (optional)

2. **Add Credentials in Jenkins:**

   Go to: `Manage Jenkins` → `Manage Credentials` → `Global`

   - **dockerhub-credentials:**
     - Kind: Username with password
     - Username: Your Docker Hub username
     - Password: Your Docker Hub password

   - **aws-credentials:**
     - Kind: AWS Credentials
     - Access Key ID: `YOUR_AWS_ACCESS_KEY_ID`
     - Secret Access Key: `YOUR_AWS_SECRET_ACCESS_KEY`

   - **sonarqube-token:**
     - Kind: Secret text
     - Secret: (Generate from SonarQube after setup)

   - **snyk-token:**
     - Kind: Secret text
     - Secret: (Get from https://snyk.io/account)

   - **kubeconfig:**
     - Kind: Secret file
     - File: Upload kubeconfig from K8s server

3. **Configure SonarQube:**

   - Access SonarQube: `http://<JENKINS_IP>:9000`
   - Default credentials: `admin/admin` (change on first login)
   - Generate authentication token: `User` → `My Account` → `Security` → `Generate Token`
   - Add token to Jenkins credentials as `sonarqube-token`

4. **Configure SonarQube Server in Jenkins:**

   Go to: `Manage Jenkins` → `Configure System` → `SonarQube servers`
   - Name: `SonarQube`
   - Server URL: `http://sonarqube:9000`
   - Server authentication token: Select `sonarqube-token`

### Step 5: Get Kubernetes Config

```bash
# SSH to K8s server
ssh -i kahoot-key.pem ubuntu@<K8S_IP>

# Get kubeconfig
/home/ubuntu/get-kubeconfig.sh

# Copy kubeconfig to your local machine
scp ubuntu@<K8S_IP>:/etc/rancher/k3s/k3s.yaml ~/.kube/k3s-config

# Update server IP in kubeconfig
sed -i 's/127.0.0.1/<K8S_PUBLIC_IP>/g' ~/.kube/k3s-config
```

Upload this kubeconfig file as a Jenkins credential named `kubeconfig`.

### Step 6: Create Jenkins Pipeline

1. Create a new Pipeline job in Jenkins
2. Configure:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/Thang141104/DevOps-Kahoot-Clone.git`
   - Branch: `fix/auth-routing-issues` or `main`
   - Script Path: `Jenkinsfile`

### Step 7: Build Docker Images

Before running the pipeline, create Dockerfiles for each service if not exist. Example structure:

```dockerfile
# Example: services/auth-service/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["node", "server.js"]
```

### Step 8: Run the Pipeline

1. Click "Build Now" in Jenkins
2. Monitor the pipeline stages:
   - ✅ Checkout
   - ✅ Install Dependencies
   - ✅ SonarQube Analysis
   - ✅ Quality Gate
   - ✅ Security Scanning (Trivy + Snyk)
   - ✅ Build Docker Images
   - ✅ Security Scan Docker Images
   - ✅ Push to Registry
   - ✅ Deploy to Kubernetes
   - ✅ Health Check

## 🔒 Security Scanning

### Trivy

Scans for:
- Filesystem vulnerabilities
- Docker image vulnerabilities
- Severity levels: HIGH and CRITICAL

### Snyk

Scans for:
- Dependency vulnerabilities
- Container vulnerabilities
- License issues
- Severity threshold: HIGH

Reports are archived as Jenkins artifacts.

## 📊 Code Quality

### SonarQube

Analyzes:
- Code smells
- Bugs
- Security vulnerabilities
- Code coverage
- Code duplication

Quality Gate must pass for pipeline to continue.

## 🐳 Docker Images

Images are tagged with:
- Build number: `kahoot-clone-<service>:<BUILD_NUMBER>`
- Latest: `kahoot-clone-<service>:latest`

## ☸️ Kubernetes Deployment

### Namespaces
- `kahoot-clone`: Application namespace

### Services
All services are deployed with:
- 2 replicas for high availability
- Resource limits and requests
- Liveness and readiness probes
- ConfigMaps for configuration
- Secrets for sensitive data

### Accessing Services

```bash
# Get all pods
kubectl get pods -n kahoot-clone

# Get all services
kubectl get services -n kahoot-clone

# Access Frontend
http://<K8S_IP>:30006

# Access Gateway
http://<K8S_IP>:30000
```

## 📁 Project Structure

```
.
├── Jenkinsfile                    # Jenkins pipeline definition
├── sonar-project.properties       # SonarQube configuration
├── terraform/
│   ├── main.tf                   # Main Terraform config
│   ├── jenkins-infrastructure.tf  # Jenkins & K8s infrastructure
│   ├── jenkins-user-data.sh      # Jenkins setup script
│   ├── k8s-user-data.sh          # K8s setup script
│   └── terraform.tfvars          # Terraform variables
├── k8s/
│   ├── namespace.yaml            # Kubernetes namespace
│   ├── configmap.yaml            # Configuration
│   ├── secrets.yaml              # Secrets
│   ├── gateway-deployment.yaml   # Gateway deployment
│   ├── auth-deployment.yaml      # Auth service deployment
│   ├── quiz-deployment.yaml      # Quiz service deployment
│   ├── game-deployment.yaml      # Game service deployment
│   ├── user-deployment.yaml      # User service deployment
│   ├── analytics-deployment.yaml # Analytics service deployment
│   └── frontend-deployment.yaml  # Frontend deployment
└── services/
    ├── gateway/
    ├── auth-service/
    ├── quiz-service/
    ├── game-service/
    ├── user-service/
    └── analytics-service/
```

## 🔧 Pipeline Stages Explained

### 1. Checkout
Clones the repository and gets the commit SHA.

### 2. Environment Setup
Verifies Node.js, npm, and Docker are installed.

### 3. Install Dependencies
Installs npm packages for all services in parallel.

### 4. SonarQube Analysis
Runs SonarQube scanner to analyze code quality.

### 5. Quality Gate
Waits for SonarQube quality gate result. Fails if quality gate fails.

### 6. Security Scanning
- **Trivy:** Scans filesystem for vulnerabilities
- **Snyk:** Scans dependencies for vulnerabilities

### 7. Build Docker Images
Builds Docker images for all services in parallel.

### 8. Security Scan Docker Images
- **Trivy:** Scans images for vulnerabilities
- **Snyk:** Scans containers for vulnerabilities

### 9. Push Docker Images
Pushes images to Docker Hub (only on main branch).

### 10. Deploy to Kubernetes
Updates image tags and deploys to Kubernetes (only on main branch).

### 11. Health Check
Verifies all pods are running and services are accessible.

## 🛠️ Troubleshooting

### Jenkins Not Starting

```bash
ssh ubuntu@<JENKINS_IP>
docker-compose -f /home/ubuntu/docker-compose.yml ps
docker-compose -f /home/ubuntu/docker-compose.yml logs jenkins
```

### SonarQube Issues

```bash
# Check SonarQube logs
docker logs sonarqube

# Restart SonarQube
docker restart sonarqube
```

### Kubernetes Pod Not Starting

```bash
kubectl describe pod <POD_NAME> -n kahoot-clone
kubectl logs <POD_NAME> -n kahoot-clone
```

### Pipeline Failing

1. Check Jenkins console output
2. Review archived artifacts (security scan reports)
3. Check SonarQube dashboard
4. Verify credentials are set correctly

## 📝 Environment Variables

### Required in Jenkins Credentials:
- `dockerhub-credentials`: Docker Hub username/password
- `aws-credentials`: AWS Access Key and Secret
- `sonarqube-token`: SonarQube authentication token
- `snyk-token`: Snyk API token
- `kubeconfig`: Kubernetes config file

### ConfigMap (k8s/configmap.yaml):
- Service URLs
- Port configurations
- CORS settings

### Secrets (k8s/secrets.yaml):
- MongoDB URI
- JWT Secret
- Email credentials

## 🔄 Continuous Deployment

The pipeline automatically deploys to Kubernetes when:
- Branch is `main`
- All tests pass
- Quality gate passes
- Security scans complete (warnings allowed)

## 📈 Monitoring

### Jenkins Dashboard
- Build history
- Test results
- Code coverage reports
- Security scan reports

### SonarQube Dashboard
- Code quality metrics
- Security hotspots
- Technical debt

### Kubernetes Dashboard

```bash
kubectl get pods -n kahoot-clone --watch
kubectl top pods -n kahoot-clone
```

## 🔐 Security Best Practices

1. ✅ All secrets stored in Kubernetes Secrets
2. ✅ Security scanning in pipeline (Trivy + Snyk)
3. ✅ Code quality checks (SonarQube)
4. ✅ Docker images scanned before deployment
5. ✅ RBAC enabled in Kubernetes
6. ✅ Network policies for service isolation

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Snyk Documentation](https://docs.snyk.io/)

## 🆘 Support

For issues or questions:
1. Check troubleshooting section
2. Review Jenkins console logs
3. Check service logs in Kubernetes
4. Review security scan reports

## 📜 License

This project is part of a DevOps learning exercise.

---

**Created:** November 2025
**Last Updated:** November 2025
**Version:** 1.0.0
