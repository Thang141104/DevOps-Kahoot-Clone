# SonarQube Architecture & Resource Usage

## 🏗️ Where Does SonarQube Run?

### Architecture Overview
```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Infrastructure                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐        ┌─────────────────────────┐   │
│  │  Jenkins EC2     │        │  Kubernetes Cluster     │   │
│  │  (t3.medium)     │        │  (t3.medium x3)         │   │
│  │                  │        │                         │   │
│  │  ┌────────────┐  │        │  ┌──────────────────┐  │   │
│  │  │ Jenkins    │  │        │  │ SonarQube Server │  │   │
│  │  │ Server     │  │───API──┼─▶│ (namespace:      │  │   │
│  │  │            │  │  calls │  │  sonarqube)      │  │   │
│  │  └────────────┘  │        │  │                  │  │   │
│  │                  │        │  │ Resources:       │  │   │
│  │  ┌────────────┐  │        │  │ - CPU: 1-2 cores │  │   │
│  │  │ sonar-     │  │        │  │ - RAM: 2-4 GB    │  │   │
│  │  │ scanner    │  │        │  │ - Storage: 10GB  │  │   │
│  │  │ CLI        │  │        │  └──────────────────┘  │   │
│  │  │ (~200MB)   │  │        │                         │   │
│  │  └────────────┘  │        │  ┌──────────────────┐  │   │
│  │                  │        │  │ PostgreSQL DB    │  │   │
│  └──────────────────┘        │  │ (~512 MB RAM)    │  │   │
│                              │  └──────────────────┘  │   │
│                              │                         │   │
│                              │  ┌──────────────────┐  │   │
│                              │  │ Your Services    │  │   │
│                              │  │ (gateway, auth,  │  │   │
│                              │  │  user, etc.)     │  │   │
│                              │  └──────────────────┘  │   │
│                              └─────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 📍 SonarQube Components

### 1. SonarQube Server (runs on K8s)
**Location:** Kubernetes cluster, namespace `sonarqube`

**Deployment:**
```yaml
# k8s/sonarqube-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sonarqube
  namespace: sonarqube  # ← Isolated namespace
spec:
  containers:
  - name: sonarqube
    image: sonarqube:10-community
    resources:
      requests:
        memory: "2Gi"      # Minimum 2GB
        cpu: "1000m"       # 1 CPU core
      limits:
        memory: "4Gi"      # Maximum 4GB
        cpu: "2000m"       # 2 CPU cores
```

**Access:**
- **From Jenkins:** `http://sonarqube.sonarqube.svc.cluster.local:9000`
- **From Browser:** `http://<k8s-node-ip>:30900`

**Resource consumption:**
- CPU: 1-2 cores (on K8s nodes, NOT Jenkins)
- RAM: 2-4 GB (on K8s nodes, NOT Jenkins)
- Storage: 10 GB PersistentVolume

### 2. PostgreSQL Database (runs on K8s)
**Location:** Same namespace as SonarQube

**Resource consumption:**
- CPU: 0.5 cores
- RAM: 512 MB
- Storage: Shared with SonarQube

### 3. Sonar-Scanner CLI (runs on Jenkins)
**Location:** Jenkins EC2 instance

**What it does:**
- Reads your source code
- Analyzes code locally
- Sends results to SonarQube server via HTTP API
- Does NOT run the full SonarQube server

**Resource consumption on Jenkins:**
- CPU: 1 core during scan (~3 minutes)
- RAM: ~200 MB
- Disk: ~100 MB for scanner binaries

## 💾 Memory Impact Analysis

### Jenkins EC2 (t3.medium - 4 GB RAM)
```
Base Jenkins:              500 MB
Jenkins JVM:               800 MB
Docker daemon:             500 MB
BuildKit cache:            500 MB
NPM installs (4 parallel): 800 MB
sonar-scanner CLI:         200 MB  ← Only this part runs on Jenkins
Docker builds (2 parallel):700 MB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Peak usage:              ~3.5 GB  ✅ Fits in 4 GB!
```

### K8s Cluster (3x t3.medium - 12 GB total)
```
K8s system components:     1.5 GB
SonarQube server:          2-4 GB  ← SonarQube runs here
PostgreSQL:                512 MB
Your services (7):         4 GB
Remaining:                 ~2 GB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total usage:             ~8-10 GB  ✅ Fits in 12 GB!
```

## 🔄 How Jenkins Communicates with SonarQube

### Step-by-Step Process

1. **Jenkins Stage: Install sonar-scanner**
```bash
# On Jenkins EC2
wget sonar-scanner-cli.zip
unzip sonar-scanner-cli.zip
# Scanner is now available on Jenkins
```

2. **Jenkins Stage: Run Analysis**
```bash
# On Jenkins EC2
sonar-scanner \
  -Dsonar.projectKey=kahoot-clone \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://sonarqube.sonarqube.svc.cluster.local:9000 \
  -Dsonar.login=${SONAR_TOKEN}

# This command:
# - Analyzes code files on Jenkins
# - Sends results via HTTP API to SonarQube server on K8s
# - Uses ~200 MB RAM on Jenkins
```

3. **SonarQube Server: Process Results**
```
# On K8s cluster
SonarQube server receives analysis results
Stores in PostgreSQL database
Runs quality gate checks
Returns pass/fail to Jenkins
```

4. **Jenkins Stage: Check Quality Gate**
```bash
# Jenkins waits for quality gate result from SonarQube
# If quality gate passes: Continue pipeline
# If quality gate fails: Report but continue (TRIVY_EXIT_CODE='0')
```

## 🎯 Key Points

### ✅ SonarQube Server DOES NOT run on Jenkins
- Runs on K8s cluster in isolated namespace
- Has its own resource allocation (2-4 GB RAM)
- Does not consume Jenkins EC2 resources

### ✅ Jenkins Only Runs Lightweight Scanner
- sonar-scanner CLI: ~200 MB RAM
- Temporary during scan only (~3 minutes)
- Sends data to SonarQube server via API

### ✅ Resource Separation
```
Jenkins EC2 (4 GB):
├─ Jenkins server
├─ Docker builds
├─ NPM installs
└─ sonar-scanner CLI (200 MB)

K8s Cluster (12 GB):
├─ SonarQube server (2-4 GB)
├─ PostgreSQL (512 MB)
└─ Your microservices (7 services)
```

## 📊 Deployment Steps

### 1. Deploy SonarQube to K8s
```bash
# Run once to create SonarQube infrastructure
kubectl apply -f k8s/sonarqube-deployment.yaml

# This creates:
# - Namespace: sonarqube
# - Deployment: sonarqube (2-4 GB RAM on K8s)
# - Deployment: postgres (512 MB RAM on K8s)
# - Service: NodePort 30900
# - PersistentVolume: 10 GB
```

### 2. Configure Jenkins to Use SonarQube
```bash
# Jenkins only needs:
# 1. SonarQube URL (to know where to send results)
# 2. Authentication token (to authenticate API calls)

# In Jenkins credentials:
ID: sonarqube-token
Secret: <generated-from-sonarqube-ui>
```

### 3. Pipeline Runs
```
Jenkins Pipeline:
├─ Stage 1: Checkout code (on Jenkins)
├─ Stage 2: Run sonar-scanner (on Jenkins)
│            └─ Sends results via API to K8s SonarQube
├─ Stage 3: Build Docker images (on Jenkins)
└─ Stage 4: Deploy to K8s
```

## 🔍 Verification

### Check SonarQube is Running on K8s
```bash
# List SonarQube pods
kubectl get pods -n sonarqube

# Expected output:
# NAME                         READY   STATUS    RESTARTS   AGE
# sonarqube-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
# postgres-xxxxxxxxxx-xxxxx    1/1     Running   0          5m
```

### Check Resource Usage on K8s
```bash
# Monitor SonarQube resource consumption
kubectl top pod -n sonarqube

# Expected output:
# NAME                         CPU(cores)   MEMORY(bytes)
# sonarqube-xxx                800m         2.5Gi
# postgres-xxx                 100m         400Mi
```

### Check Jenkins NOT Running SonarQube Server
```bash
# SSH to Jenkins EC2
ssh -i terraform/jenkins-key.pem ubuntu@<jenkins-ip>

# Check running containers
docker ps

# You will NOT see SonarQube server container
# You will only see:
# - Jenkins container
# - Temporary build containers
```

## 💡 Summary

| Component | Where | CPU | RAM | Affects Jenkins? |
|-----------|-------|-----|-----|------------------|
| **SonarQube Server** | K8s Cluster | 1-2 cores | 2-4 GB | ❌ No |
| **PostgreSQL** | K8s Cluster | 0.5 cores | 512 MB | ❌ No |
| **sonar-scanner CLI** | Jenkins EC2 | 1 core* | 200 MB | ✅ Yes (minimal) |
| **Your Services** | K8s Cluster | Varies | ~4 GB | ❌ No |

*Only during scan (~3 minutes), runs in parallel with npm installs

**Conclusion:** SonarQube server does NOT impact Jenkins EC2 resources. The t3.medium (4 GB) Jenkins instance is sufficient because it only runs the lightweight scanner CLI.
