# Kahoot Clone - Enterprise Microservices Platform

A production-ready, cloud-native Kahoot clone demonstrating enterprise-level DevOps practices including microservices architecture, CI/CD automation, Infrastructure as Code, container orchestration, and comprehensive monitoring.

[![Production Ready](https://img.shields.io/badge/Production-Ready-green.svg)](https://github.com/yourusername/kahoot-clone)
[![K8s](https://img.shields.io/badge/K8s-3%20Nodes-blue.svg)](https://kubernetes.io/)
[![Test Coverage](https://img.shields.io/badge/Coverage-80%25-brightgreen.svg)](./services)
[![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%2FGrafana-orange.svg)](./docs/monitoring)
[![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform%20%2B%20Ansible-purple.svg)](./infrastructure)

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Quick Start](#quick-start)
- [Infrastructure Deployment](#infrastructure-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Observability](#monitoring--observability)
- [Testing](#testing)
- [Security](#security)
- [Project Structure](#project-structure)
- [API Documentation](#api-documentation)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Project Overview

This project demonstrates enterprise-grade DevOps practices through a complete quiz/game platform implementation featuring:

### Core Features

- **Real-time Multiplayer Quiz Gameplay**: WebSocket-based interactive game sessions
- **User Authentication System**: JWT-based auth with OTP email verification
- **Quiz Management**: Create, edit, and organize quiz content
- **Analytics & Leaderboards**: Comprehensive game statistics and rankings
- **User Profiles**: AWS S3-backed avatar storage and user achievements
- **Email Notifications**: Automated email system with Nodemailer

### DevOps Highlights

- **Microservices Architecture**: 7 independent services with clear boundaries
- **Cloud Infrastructure**: AWS-based deployment (EC2, ECR, S3, VPC)
- **Container Orchestration**: Kubernetes cluster (3 nodes - 1 master, 2 workers)
- **CI/CD Automation**: Jenkins pipeline with GitHub webhook integration
- **Infrastructure as Code**: Terraform for provisioning, Ansible for configuration
- **Monitoring Stack**: Prometheus + Grafana for metrics and visualization
- **Code Quality**: SonarQube static analysis integration
- **Security Scanning**: Trivy vulnerability scanning for images and repositories
- **Smart Builds**: Nx integration for affected service detection

## Architecture

### System Architecture

```
┌─────────────┐
│   Users     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Load Balancer (Kubernetes Ingress) │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────┐
│   Gateway   │  (Port 3000)
│  (Express)  │
└──────┬──────┘
       │
       ├──────────┬─────────┬──────────┬──────────┬─────────┐
       ▼          ▼         ▼          ▼          ▼         ▼
   ┌───────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌────────┐
   │ Auth  │  │ User │  │ Quiz │  │ Game │  │Analyt│  │Frontend│
   │Service│  │Svc   │  │Svc   │  │Svc   │  │ics   │  │ (React)│
   │:3001  │  │:3002 │  │:3003 │  │:3004 │  │:3005 │  │:80     │
   └───┬───┘  └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘  └────────┘
       │         │         │         │         │
       └─────────┴─────────┴─────────┴─────────┘
                          │
                          ▼
                   ┌────────────┐
                   │  MongoDB   │
                   │  (Atlas)   │
                   └────────────┘
```

### Infrastructure Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        AWS Cloud (us-east-1)                  │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              VPC (10.0.0.0/16)                       │   │
│  │                                                       │   │
│  │  ┌──────────────────┐  ┌────────────────────────┐   │   │
│  │  │  Public Subnet   │  │   Private Subnet       │   │   │
│  │  │  (10.0.1.0/24)   │  │   (10.0.2.0/24)        │   │   │
│  │  │                  │  │                        │   │   │
│  │  │  ┌────────────┐  │  │  ┌──────────────────┐ │   │   │
│  │  │  │  Jenkins   │  │  │  │  K8s Master Node │ │   │   │
│  │  │  │(c7i-flex)  │  │  │  │  (c7i-flex.large)│ │   │   │
│  │  │  └────────────┘  │  │  └──────────────────┘ │   │   │
│  │  │                  │  │                        │   │   │
│  │  │                  │  │  ┌──────────────────┐ │   │   │
│  │  │                  │  │  │  K8s Worker-1    │ │   │   │
│  │  │                  │  │  │  (c7i-flex.large)│ │   │   │
│  │  │                  │  │  └──────────────────┘ │   │   │
│  │  │                  │  │                        │   │   │
│  │  └──────────────────┘  │  ┌──────────────────┐ │   │   │
│  │                        │  │  K8s Worker-2    │ │   │   │
│  │                        │  │  (c7i-flex.large)│ │   │   │
│  │                        │  └──────────────────┘ │   │   │
│  │                        └────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │     ECR      │  │      S3      │  │   Secrets       │   │
│  │ (Container   │  │  (User       │  │   Manager       │   │
│  │  Registry)   │  │  Avatars)    │  │                 │   │
│  └──────────────┘  └──────────────┘  └─────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

### Microservices Overview

| Service | Port | Purpose | Key Technologies |
|---------|------|---------|-----------------|
| **Gateway** | 3000 | API routing, rate limiting, CORS | Express.js |
| **Auth Service** | 3001 | Authentication, JWT, OTP verification | Express, JWT, Nodemailer |
| **User Service** | 3002 | User profiles, avatars (S3), achievements | Express, Multer, AWS SDK |
| **Quiz Service** | 3003 | Quiz CRUD, question management | Express, Mongoose, Joi |
| **Game Service** | 3004 | Real-time game sessions, leaderboards | Express, Socket.io |
| **Analytics Service** | 3005 | Statistics, game history, reporting | Express, MongoDB Aggregation |
| **Frontend** | 80/3006 | React SPA, responsive UI | React 18, Socket.io-client |

## Technology Stack

### Frontend
- **Framework**: React 18.x
- **State Management**: React Hooks, Context API
- **Styling**: CSS3, Responsive Design
- **Real-time Communication**: Socket.io-client
- **HTTP Client**: Axios
- **Build Tool**: Webpack, Babel

### Backend
- **Runtime**: Node.js 18.x LTS
- **Framework**: Express.js 4.x
- **Database**: MongoDB Atlas (Cloud-hosted)
- **Authentication**: JWT (jsonwebtoken), bcrypt
- **File Upload**: Multer, AWS S3 SDK v3
- **Image Processing**: Sharp
- **Email**: Nodemailer
- **Validation**: Joi
- **Monitoring**: prom-client (Prometheus metrics)
- **Logging**: Winston

### DevOps & Infrastructure
- **Containerization**: Docker 24.x, Docker Compose
- **Orchestration**: Kubernetes 1.28 (kubeadm)
- **CI/CD**: Jenkins with Pipeline
- **Infrastructure as Code**: Terraform 1.5+
- **Configuration Management**: Ansible 2.15+
- **Cloud Provider**: AWS (EC2, ECR, S3, VPC)
- **Container Registry**: AWS ECR
- **Monitoring**: Prometheus 2.x, Grafana 10.x
- **Code Quality**: SonarQube Community Edition
- **Security Scanning**: Trivy
- **Version Control**: Git, GitHub
- **Smart Builds**: Nx with remote caching (S3)

## Quick Start

### Prerequisites

Before you begin, ensure you have:

- **Node.js** v18.x or higher ([Download](https://nodejs.org/))
- **Docker** v20.x or higher ([Install Guide](https://docs.docker.com/get-docker/))
- **Docker Compose** v2.x or higher
- **Git** v2.x or higher
- **MongoDB Atlas Account** (free tier available)
- **AWS Account** (for cloud deployment)
- **kubectl** v1.28+ (for Kubernetes)
- **Terraform** v1.5+ (for infrastructure)

### Local Development Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/DevOps-Kahoot-Clone.git
cd DevOps-Kahoot-Clone
```

#### 2. Configure Environment Variables

Create `.env` file in the root directory:

```bash
# Copy example file
cp .env.example .env
```

Edit `.env` with your configurations:

```env
# MongoDB
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/kahoot-clone

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_EXPIRY=24h

# Email Configuration
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-specific-password

# AWS Configuration (for S3 avatars)
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_REGION=us-east-1
S3_AVATAR_BUCKET=kahoot-avatars

# Service URLs
GATEWAY_URL=http://localhost:3000
FRONTEND_URL=http://localhost:3006
```

#### 3. Start with Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check service health
docker-compose ps

# Stop services
docker-compose down
```

#### 4. Access the Application

- **Frontend**: http://localhost:3001
- **API Gateway**: http://localhost:3000
- **Gateway Health Check**: http://localhost:3000/health

### Running Individual Services (Development)

For development with hot-reload:

```bash
# Terminal 1 - Gateway
cd gateway
npm install
npm run dev

# Terminal 2 - Auth Service
cd services/auth-service
npm install
npm run dev

# Terminal 3 - Frontend
cd frontend
npm install
npm start
```

## Infrastructure Deployment

### Step 1: Provision AWS Infrastructure with Terraform

The Terraform configuration creates:
- VPC with public/private subnets
- Internet Gateway and NAT Gateway
- Security Groups
- EC2 instances (Jenkins, K8s nodes)
- ECR repository
- S3 bucket for avatars
- IAM roles and policies

```powershell
# Navigate to terraform directory
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply infrastructure (creates all AWS resources)
terraform apply -auto-approve

# Save outputs for later use
terraform output > outputs.txt

# Get specific output
terraform output jenkins_public_ip
terraform output k8s_master_ip
```

**Expected Resources Created:**
- 1x VPC
- 2x Subnets (public/private)
- 1x Internet Gateway
- 3x Security Groups
- 4x EC2 Instances (1 Jenkins c7i-flex.large, 1 K8s Master, 2 K8s Workers)
- 1x ECR Repository
- 2x S3 Buckets (avatars, Nx cache)
- Multiple IAM Roles/Policies
- SonarQube deployed in K8s cluster (not standalone EC2)

### Step 2: Configure Kubernetes Cluster with Ansible

```powershell
cd infrastructure/ansible

# Update inventory with Terraform outputs
# Edit inventory/hosts.ini with actual IP addresses

# Install Ansible (if not already installed)
# Windows: use WSL or install via pip
pip install ansible

# Verify connectivity
ansible all -i inventory/hosts.ini -m ping

# Run full playbook (installs K8s, Jenkins, monitoring)
ansible-playbook -i inventory/hosts.ini site.yml

# Or run specific roles
ansible-playbook -i inventory/hosts.ini site.yml --tags kubernetes
ansible-playbook -i inventory/hosts.ini site.yml --tags monitoring
```

**What Ansible Configures:**
- Kubernetes cluster (kubeadm init/join)
- Container runtime (containerd)
- CNI plugin (Calico)
- Jenkins on c7i-flex.large with required plugins
- Docker and Docker Compose
- Monitoring stack in K8s (Prometheus, Grafana, SonarQube)
- Required system packages

### Step 3: Configure kubectl

```bash
# Get kubeconfig from master node
scp ubuntu@<k8s-master-ip>:~/.kube/config ~/.kube/config

# Verify cluster
kubectl get nodes
kubectl cluster-info
```

### Step 4: Deploy Application to Kubernetes

#### Create Secrets

```bash
# Create namespace
kubectl create namespace kahoot-clone

# MongoDB connection string
kubectl create secret generic mongodb-secret \
  --from-literal=connection-string='mongodb+srv://...' \
  -n kahoot-clone

# JWT secret
kubectl create secret generic jwt-secret \
  --from-literal=secret='your-jwt-secret' \
  -n kahoot-clone

# Email credentials
kubectl create secret generic email-secret \
  --from-literal=email='your-email@gmail.com' \
  --from-literal=password='your-app-password' \
  -n kahoot-clone

# AWS credentials (for S3)
kubectl create secret generic aws-secret \
  --from-literal=access-key-id='your-aws-key' \
  --from-literal=secret-access-key='your-aws-secret' \
  -n kahoot-clone

# ECR registry secret
aws ecr get-login-password --region us-east-1 | \
  kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=<account-id>.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password-stdin \
  -n kahoot-clone
```

#### Deploy Services

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/base/configmap.yaml
kubectl apply -f k8s/services/
kubectl apply -f k8s/frontend/

# Check deployment status
kubectl get pods -n kahoot-clone
kubectl get services -n kahoot-clone
kubectl get deployments -n kahoot-clone

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=gateway -n kahoot-clone --timeout=300s
```

#### Verify Deployment

```bash
# Check pod logs
kubectl logs -f deployment/gateway -n kahoot-clone

# Get service endpoints
kubectl get svc -n kahoot-clone

# Access application
# Frontend: http://<master-node-ip>:30001
# Gateway: http://<master-node-ip>:30000
```

### Step 5: Deploy Monitoring Stack

```bash
# Deploy Prometheus and Grafana
ansible-playbook -i inventory/hosts.ini site.yml --tags monitoring

# Or apply manually
kubectl apply -f k8s/monitoring/

# Access dashboards
# Prometheus: http://<master-ip>:30090
# Grafana: http://<master-ip>:30300
# Default Grafana credentials: admin / admin123
```

## CI/CD Pipeline

### Jenkins Setup

Jenkins is automatically provisioned and configured via Terraform and Ansible.

**Access Jenkins:**
1. Navigate to: `http://<jenkins-ip>:8080`
2. Jenkins runs on c7i-flex.large instance
3. Get initial admin password:
   ```bash
   ssh ubuntu@<jenkins-ip>
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
4. Complete setup wizard
5. Install recommended plugins

### Pipeline Configuration

The `Jenkinsfile` defines a comprehensive CI/CD pipeline with the following stages:

#### Stage 1: Initialization
- Checkout source code from GitHub
- Display build information
- Setup environment variables

#### Stage 2: Setup Nx
- Install Nx for smart builds
- Create S3 bucket for remote cache
- Configure lifecycle policies

#### Stage 3: Detect Affected Services
- Use Nx to determine which services changed
- Only build/test affected services
- Significant build time savings

#### Stage 4: Security Scan (Parallel)
- **Trivy Repository Scan**: Scan source code for vulnerabilities
- **SonarQube Analysis**: Static code analysis for quality and security

#### Stage 5: ECR Login
- Authenticate to AWS ECR
- Prepare for Docker image push

#### Stage 6: Install Dependencies
- Run `npm ci` for all services in parallel batches
- Optimized for t3.medium instance (4GB RAM)

#### Stage 7: Build & Push Docker Images (Parallel)
- Build Docker images with BuildKit
- Use layer caching from ECR
- Tag with build number and 'latest'
- Push to ECR registry
- Builds in 2 batches to manage resources

#### Stage 8: Security Scan - Images (Parallel)
- Scan all Docker images with Trivy
- Check for HIGH and CRITICAL vulnerabilities
- Non-blocking (report only)

#### Stage 9: Pre-Deployment Validation
- Generate security reports
- Archive artifacts

#### Stage 10: Deploy to Kubernetes
- SSH to K8s master node
- Update ECR pull secrets
- Apply/update Kubernetes deployments
- Update image tags to new build version
- Force rollout restart
- Clean up failed pods
- Wait for deployment completion

### GitHub Webhook Configuration

To trigger builds automatically on push:

1. Go to GitHub repository > Settings > Webhooks
2. Add webhook:
   - **Payload URL**: `http://<jenkins-ip>:8080/generic-webhook-trigger/invoke?token=kahoot-clone-webhook-token`
   - **Content type**: application/json
   - **Events**: Just the push event
   - **Active**: Checked

3. Test webhook by pushing code:
   ```bash
   git add .
   git commit -m "test: trigger Jenkins build"
   git push origin main
   ```

### Pipeline Performance

**Optimization Features:**
- Parallel builds reduce time by ~52%
- Nx smart builds only build affected services
- Docker layer caching via BuildKit
- Remote Nx cache in S3
- Optimized npm install with `npm ci --prefer-offline`

**Build Times:**
- Initial build (all services): ~8-10 minutes
- Incremental build (1-2 services): ~3-5 minutes
- No changes: ~1-2 minutes (validation only)

## Monitoring & Observability

### Prometheus

Prometheus collects metrics from all microservices via the `/metrics` endpoint.

**Access**: `http://<k8s>:30909`

**Key Metrics Collected:**
- `http_requests_total{service, method, route, status}`: Total HTTP requests
- `http_request_duration_seconds{service}`: Request latency histogram
- `active_users_total`: Current active users
- `game_sessions_active`: Active game sessions
- `mongodb_connections_active`: Database connection pool
- `nodejs_heap_size_used_bytes`: Memory usage
- `process_cpu_seconds_total`: CPU usage

**Example Queries:**
```promql
# Request rate per service
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Active users
active_users_total

# Memory usage
nodejs_heap_size_used_bytes / 1024 / 1024
```

### Grafana

Visual dashboards for monitoring system health and performance.

**Access**: `http://<k8s-master-ip>:30300`  
**Default Credentials**: `admin` / `admin`

**Pre-configured Dashboards:**
1. **System Overview**: Overall health, request rates, error rates
2. **Service Performance**: Per-service metrics, latency percentiles
3. **Infrastructure**: CPU, memory, disk, network for all nodes
4. **Application Metrics**: Business metrics (users, games, quizzes)
5. **Database**: MongoDB connection pool, query performance

**Adding Data Source:**
1. Configuration > Data Sources > Add data source
2. Select Prometheus
3. URL: `http://prometheus:9090`
4. Save & Test

### Logging

All services use Winston for structured JSON logging.

**Log Levels:** ERROR, WARN, INFO, DEBUG

**View Logs:**
```bash
# All pods in namespace
kubectl logs -f --selector app=<service-name> -n kahoot-clone

# Specific pod
kubectl logs -f <pod-name> -n kahoot-clone

# Last N lines
kubectl logs --tail=100 <pod-name> -n kahoot-clone

# Previous container (for crashloop debugging)
kubectl logs --previous <pod-name> -n kahoot-clone

# Multiple pods
kubectl logs -f -l app=gateway -n kahoot-clone --all-containers=true
```

### Health Checks

Every service exposes health endpoints for Kubernetes probes:

```bash
# Liveness probe: /health
curl http://<service>:port/health

# Readiness probe: /ready  
curl http://<service>:port/ready
```

Kubernetes automatically restarts unhealthy pods and removes not-ready pods from service endpoints.

## Testing

### Test Coverage

Target: 80% code coverage across all services

**Test Suites:**
- Unit Tests: Jest
- Integration Tests: Supertest
- E2E Tests: (Planned: Cypress)

### Running Tests

```bash
# Run all tests for a service
cd services/auth-service
npm test

# Run with coverage
npm test -- --coverage

# Watch mode (for development)
npm run test:watch

# Run specific test file
npm test -- auth.routes.test.js

# Generate coverage report
npm test -- --coverage --coverageReporters=html
# Open: coverage/index.html
```

### Test Structure

```
services/auth-service/
├── tests/
│   ├── setup.js              # Test environment setup
│   ├── auth.routes.test.js   # Route tests
│   └── auth.service.test.js  # Business logic tests
└── jest.config.js            # Jest configuration
```

### CI Integration

Tests run automatically in Jenkins pipeline:
- On every commit/push
- Before building Docker images
- Required to pass before deployment
- Coverage reports archived as artifacts

## Security

### Authentication & Authorization

- **JWT Tokens**: Secure, stateless authentication
- **Password Hashing**: bcrypt with salt rounds
- **Token Expiration**: Configurable expiry time
- **Refresh Tokens**: (Planned)
- **OTP Verification**: Email-based two-factor authentication

### Network Security

- **VPC Isolation**: Public/private subnet segregation
- **Security Groups**: Minimal port exposure (least privilege)
- **Internal Communication**: Services communicate within cluster
- **TLS/HTTPS**: (Configured for production)

### Secrets Management

- **Kubernetes Secrets**: Encrypted at rest
- **No Hardcoded Credentials**: All secrets from environment
- **AWS Secrets Manager**: (Ready for integration)
- **Secret Rotation**: Manual (automated rotation planned)

### Vulnerability Scanning

- **Trivy**: Scans containers for CVEs
  - Repository scan: Before build
  - Image scan: After build
  - Severity levels: CRITICAL, HIGH
  - Non-blocking: Reports only

- **SonarQube**: Static code analysis
  - Code smells
  - Security vulnerabilities
  - Code duplication
  - Technical debt

### API Security

- **Rate Limiting**: Prevent abuse
- **CORS**: Configured allowed origins
- **Input Validation**: Joi schema validation
- **SQL/NoSQL Injection**: Mongoose prevents injection
- **XSS Protection**: Input sanitization

### Data Security

- **Encrypted Connections**: MongoDB over TLS
- **Encrypted Storage**: AWS S3 server-side encryption
- **Access Control**: IAM roles and policies
- **Audit Logging**: All write operations logged

## Project Structure

```
DevOps-Kahoot-Clone/
│
├── frontend/                          # React frontend SPA
│   ├── public/                        # Static assets
│   ├── src/
│   │   ├── pages/                     # React page components
│   │   ├── config/                    # API configuration
│   │   └── index.js                   # Entry point
│   ├── Dockerfile                     # Multi-stage build
│   └── package.json
│
├── gateway/                           # API Gateway
│   ├── server.js                      # Express server
│   ├── Dockerfile
│   └── package.json
│
├── services/                          # Microservices
│   ├── auth-service/                  # Authentication
│   │   ├── routes/                    # API routes
│   │   ├── models/                    # Mongoose models
│   │   ├── utils/                     # Helper functions
│   │   ├── tests/                     # Jest tests
│   │   ├── server.js
│   │   ├── Dockerfile
│   │   └── package.json
│   │
│   ├── user-service/                  # User management
│   │   ├── routes/
│   │   ├── models/
│   │   ├── middleware/                # Upload middleware
│   │   ├── utils/                     # S3 utilities
│   │   └── ...
│   │
│   ├── quiz-service/                  # Quiz CRUD
│   ├── game-service/                  # Real-time gameplay
│   └── analytics-service/             # Statistics
│
├── infrastructure/                    # Infrastructure as Code
│   ├── terraform/                     # AWS provisioning
│   │   ├── main.tf                    # Main configuration
│   │   ├── outputs.tf                 # Output values
│   │   ├── variables.tf               # Input variables
│   │   ├── terraform.tfvars.example   # Variable values template
│   │   └── modules/                   # Terraform modules
│   │       ├── networking/            # VPC, subnets, gateways
│   │       ├── compute/               # EC2 instances
│   │       ├── storage/               # S3 buckets
│   │       │   ├── s3-avatars.tf      # User avatars bucket
│   │       │   └── s3-nx-cache.tf     # Nx cache bucket
│   │       ├── ecr/                   # Container registry
│   │       ├── security/              # Security groups, IAM
│   │       └── nx-cache/              # Nx cache configuration
│   │
│   └── ansible/                       # Configuration management
│       ├── inventory/
│       │   └── hosts.ini              # Inventory file
│       ├── roles/
│       │   ├── kubernetes/            # K8s cluster setup
│       │   ├── jenkins/               # Jenkins installation
│       │   ├── monitoring/            # Prometheus & Grafana
│       │   └── common/                # Common tasks
│       ├── site.yml                   # Main playbook
│       └── ansible.cfg                # Ansible configuration
│
├── k8s/                               # Kubernetes manifests
│   ├── base/                          # Base configurations
│   │   ├── namespace.yaml             # Namespace definition
│   │   ├── configmap.yaml             # Configuration data
│   │   └── secrets.yaml.example       # Secrets template
│   ├── services/                      # Microservices deployments
│   │   ├── gateway-deployment.yaml    # Gateway deployment & service
│   │   ├── auth-deployment.yaml       # Auth service
│   │   ├── user-deployment.yaml       # User service
│   │   ├── quiz-deployment.yaml       # Quiz service
│   │   ├── game-deployment.yaml       # Game service
│   │   └── analytics-deployment.yaml  # Analytics service
│   ├── frontend/                      # Frontend deployment
│   │   └── frontend-deployment.yaml   # Frontend
│   ├── sonarqube/                     # SonarQube deployment
│   │   └── sonarqube-deployment.yaml  # SonarQube server
│   └── monitoring/                    # Monitoring stack
│       ├── prometheus-deployment.yaml
│       └── grafana-deployment.yaml
│
├── docs/                              # Documentation
│   ├── infrastructure/                # Infrastructure guides
│   │   ├── QUICKSTART.md              # Quick setup guide
│   │   └── NX_AUTOMATION.md           # Nx smart builds
│   └── deployment/                    # Deployment procedures
│
├── Jenkinsfile                        # CI/CD pipeline
├── docker-compose.yml                 # Local development
├── .env.example                       # Environment template
├── .gitignore                         # Git ignore rules
├── sonar-project.properties           # SonarQube config
├── nx.json                            # Nx configuration
└── README.md                          # This file
```

## API Documentation

### Base URLs

- **Local Gateway**: `http://localhost:3000/api`
- **Local Frontend**: `http://localhost:3006`
- **Production Gateway**: `http://<master-ip>:30000/api`
- **Production Frontend**: `http://<master-ip>:30006`

### Authentication Endpoints

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePass123!"
}

Response: 201 Created
{
  "message": "Registration successful. Please verify your email.",
  "userId": "64f5a7b9c1234567890abcde"
}
```

#### Verify OTP
```http
POST /api/auth/verify-otp
Content-Type: application/json

{
  "email": "john@example.com",
  "otp": "123456"
}

Response: 200 OK
{
  "message": "Email verified successfully"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePass123!"
}

Response: 200 OK
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "64f5a7b9c1234567890abcde",
    "username": "john_doe",
    "email": "john@example.com"
  }
}
```

### User Endpoints

#### Get Profile
```http
GET /api/users/profile/:userId
Authorization: Bearer <jwt-token>

Response: 200 OK
{
  "user": {
    "id": "64f5a7b9c1234567890abcde",
    "username": "john_doe",
    "email": "john@example.com",
    "avatar": "https://s3.amazonaws.com/kahoot-avatars/user-id.jpg",
    "achievements": [],
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

#### Upload Avatar
```http
POST /api/users/profile/:userId/avatar
Authorization: Bearer <jwt-token>
Content-Type: multipart/form-data

FormData:
  avatar: <image-file> (max 5MB, JPEG/PNG)

Response: 200 OK
{
  "message": "Avatar uploaded successfully",
  "avatarUrl": "https://s3.amazonaws.com/kahoot-avatars/user-id.jpg"
}
```

### Quiz Endpoints

#### List Quizzes
```http
GET /api/quizzes?page=1&limit=10
Authorization: Bearer <jwt-token>

Response: 200 OK
{
  "quizzes": [
    {
      "id": "quiz-id",
      "title": "JavaScript Fundamentals",
      "description": "Test your JS knowledge",
      "questionCount": 10,
      "createdBy": "john_doe",
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ],
  "total": 42,
  "page": 1,
  "pages": 5
}
```

#### Create Quiz
```http
POST /api/quizzes
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "title": "JavaScript Fundamentals",
  "description": "Test your JS knowledge",
  "questions": [
    {
      "text": "What is a closure?",
      "options": [
        "A function inside a function",
        "A loop structure",
        "A data type",
        "A library"
      ],
      "correctAnswer": 0,
      "timeLimit": 30,
      "points": 100
    }
  ]
}

Response: 201 Created
{
  "message": "Quiz created successfully",
  "quizId": "quiz-id"
}
```

### Game Endpoints

#### Create Game Session
```http
POST /api/games/create
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "quizId": "quiz-id",
  "hostId": "user-id"
}

Response: 201 Created
{
  "gameId": "game-id",
  "gamePin": "123456",
  "status": "waiting"
}
```

#### Join Game
```http
POST /api/games/join
Content-Type: application/json

{
  "gamePin": "123456",
  "playerName": "Player1"
}

Response: 200 OK
{
  "message": "Joined game successfully",
  "gameId": "game-id",
  "playerId": "player-id"
}
```

For complete API documentation, refer to individual service README files in `services/` directories.

## Troubleshooting

### Common Issues

#### 1. Pods Stuck in Pending State

**Cause**: Insufficient resources or scheduling issues

**Solution**:
```bash
# Check node resources
kubectl top nodes

# Describe pod for events
kubectl describe pod <pod-name> -n kahoot-clone

# Check for resource constraints
kubectl get pods -n kahoot-clone -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].resources}{"\n"}{end}'

# Scale down if needed
kubectl scale deployment <deployment-name> --replicas=1 -n kahoot-clone
```

#### 2. ImagePullBackOff Error

**Cause**: Cannot pull Docker image from ECR

**Solution**:
```bash
# Verify ECR secret exists
kubectl get secrets ecr-registry-secret -n kahoot-clone

# Recreate ECR secret
kubectl delete secret ecr-registry-secret -n kahoot-clone

aws ecr get-login-password --region us-east-1 | \
  kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=<account-id>.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password-stdin \
  -n kahoot-clone

# Verify image exists in ECR
aws ecr describe-images --repository-name kahoot-clone-gateway --region us-east-1

# Force pod restart
kubectl rollout restart deployment/<deployment-name> -n kahoot-clone
```

#### 3. CrashLoopBackOff

**Cause**: Application crashing at startup

**Solution**:
```bash
# Check pod logs
kubectl logs <pod-name> -n kahoot-clone --previous

# Common causes:
# - Missing environment variables
# - Invalid MongoDB connection string
# - Port already in use
# - Missing dependencies

# Verify secrets
kubectl get secrets -n kahoot-clone
kubectl describe secret mongodb-secret -n kahoot-clone

# Check configmap
kubectl get configmap -n kahoot-clone
kubectl describe configmap app-config -n kahoot-clone

# Exec into pod (if running)
kubectl exec -it <pod-name> -n kahoot-clone -- /bin/sh
env | grep MONGO  # Check environment variables
```

#### 4. MongoDB Connection Errors

**Symptoms**: "MongooseServerSelectionError" in logs

**Solutions**:
- **Verify connection string format**:
  ```
  mongodb+srv://username:password@cluster.mongodb.net/database?retryWrites=true&w=majority
  ```
- **Check MongoDB Atlas IP whitelist**:
  - Add `0.0.0.0/0` for testing
  - Add specific EC2 public IPs for production
- **Verify credentials**: Username, password, database name
- **Test connectivity**:
  ```bash
  kubectl run -it --rm debug --image=mongo:latest --restart=Never -- \
    mongosh "mongodb+srv://..."
  ```

#### 5. Jenkins Build Failures

**Common Errors**:

**a) Docker daemon not available**
```bash
# SSH to Jenkins server
ssh ubuntu@<jenkins-ip>

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

**b) AWS CLI not configured**
```bash
# Configure AWS credentials on Jenkins server
ssh ubuntu@<jenkins-ip>
sudo su - jenkins
aws configure
# Enter: Access Key, Secret Key, Region (us-east-1), Output format (json)
```

**c) Insufficient disk space**
```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a -f --volumes

# Clean up old builds
rm -rf /var/lib/jenkins/workspace/*
```

#### 6. Nx Smart Builds Not Working

**Solution**:
```bash
# Verify Nx installation
npx nx --version

# Clear Nx cache
npx nx reset

# Manually trigger affected detection
npx nx affected:apps --base=HEAD~1

# Check S3 remote cache
aws s3 ls s3://kahoot-nx-cache-<account-id>/
```

#### 7. Prometheus Not Scraping Metrics

**Cause**: Service discovery or network issues

**Solution**:
```bash
# Check Prometheus targets
# Visit: http://<master-ip>:30090/targets

# Verify service has /metrics endpoint
kubectl exec -it <pod-name> -n kahoot-clone -- curl localhost:3001/metrics

# Check Prometheus config
kubectl get configmap prometheus-config -n kahoot-clone -o yaml

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n kahoot-clone
```

#### 8. Grafana Dashboards Empty

**Solutions**:
```bash
# Verify Prometheus datasource
# Grafana > Configuration > Data Sources

# Check Prometheus URL: http://prometheus:9090

# Verify metrics exist
# Prometheus > Graph > Execute query: up

# Re-import dashboards
# Grafana > Dashboards > Import
```

### Getting Help

1. **Check logs**: Always start with `kubectl logs`
2. **Describe resources**: `kubectl describe pod/deployment/service`
3. **GitHub Issues**: [Report bugs or request features](https://github.com/yourusername/DevOps-Kahoot-Clone/issues)
4. **Documentation**: Review `/docs` directory for detailed guides

## Contributing

We welcome contributions! Please follow these guidelines:

### Development Workflow

1. **Fork the repository**
2. **Clone your fork**:
   ```bash
   git clone https://github.com/your-username/DevOps-Kahoot-Clone.git
   ```
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/amazing-feature
   ```
4. **Make your changes**
5. **Write/update tests**
6. **Run tests**:
   ```bash
   npm test
   ```
7. **Commit your changes**:
   ```bash
   git commit -m "feat: add amazing feature"
   ```
8. **Push to your fork**:
   ```bash
   git push origin feature/amazing-feature
   ```
9. **Create a Pull Request**

### Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples**:
```
feat(auth): add OTP email verification
fix(quiz): resolve question validation bug
docs(readme): update installation instructions
test(game): add unit tests for game logic
```

### Code Style

- Follow JavaScript Standard Style
- Use ESLint and Prettier
- Write clear, self-documenting code
- Add comments for complex logic
- Keep functions small and focused

### Testing Requirements

- Maintain 80% code coverage
- Write unit tests for all new functions
- Add integration tests for API endpoints
- Update E2E tests if UI changes

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Technologies**: Node.js, React, MongoDB, Kubernetes, AWS
- **Inspiration**: Kahoot! learning platform
- **Community**: Open-source contributors

## Contact

**Project Repository**: https://github.com/yourusername/DevOps-Kahoot-Clone  
**Issues**: https://github.com/yourusername/DevOps-Kahoot-Clone/issues  
**Maintainer**: DevOps Team

---

**Status**: Production Ready  
**Last Updated**: December 2025  
**Version**: 1.0.0
