# 📊 Kubernetes Deployment & Monitoring Guide - Kahoot Clone

> Hướng dẫn đầy đủ triển khai Kubernetes với Prometheus & Grafana monitoring cho Kahoot Clone

---

## 📋 **Mục Lục**

1. [Tổng Quan Hệ Thống](#1-tổng-quan-hệ-thống)
2. [Prerequisites](#2-prerequisites)
3. [Bước 1: Triển Khai Infrastructure với Terraform](#3-bước-1-triển-khai-infrastructure)
4. [Bước 2: Cấu Hình Jenkins](#4-bước-2-cấu-hình-jenkins)
5. [Bước 3: Thêm Application Metrics](#5-bước-3-thêm-application-metrics)
6. [Bước 4: Deploy lên Kubernetes](#6-bước-4-deploy-lên-kubernetes)
7. [Bước 5: Cấu Hình Grafana Dashboards](#7-bước-5-cấu-hình-grafana)
8. [Bước 6: Monitoring & Troubleshooting](#8-bước-6-monitoring--troubleshooting)
9. [Commands Cheat Sheet](#9-commands-cheat-sheet)

---

## 1. Tổng Quan Hệ Thống

### **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Jenkins       │  │  K8s Master     │  │  App Server │ │
│  │   + SonarQube   │  │  + Prometheus   │  │  (Optional) │ │
│  │                 │  │  + Grafana      │  │             │ │
│  │  c7i-flex.large │  │  c7i-flex.large │  │  t3.small   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
│         │                      │                             │
│         └──────────────────────┘                             │
│                    │                                          │
│         ┌──────────┴──────────┐                             │
│         ▼                      ▼                             │
│  ┌─────────────┐       ┌─────────────┐                      │
│  │  Namespace  │       │  Namespace  │                      │
│  │ kahoot-clone│       │ monitoring  │                      │
│  ├─────────────┤       ├─────────────┤                      │
│  │ • gateway   │       │ • Prometheus│                      │
│  │ • auth      │       │ • Grafana   │                      │
│  │ • quiz      │       └─────────────┘                      │
│  │ • game      │                                             │
│  │ • user      │                                             │
│  │ • analytics │                                             │
│  │ • frontend  │                                             │
│  └─────────────┘                                             │
└─────────────────────────────────────────────────────────────┘
```

### **Monitoring Stack**

```
Application Services → /metrics endpoint
         ↓
    Prometheus (scrape every 15s)
         ↓
    Store metrics in TSDB
         ↓
    Grafana (visualize)
         ↓
    Dashboards & Alerts
```

---

## 2. Prerequisites

### **Công Cụ Cần Có:**

- ✅ AWS Account với credentials
- ✅ Terraform v1.14+
- ✅ AWS CLI configured
- ✅ SSH key pair (kahoot-key.pem)
- ✅ Docker Hub account
- ✅ Git & GitHub account

### **Kiểm Tra:**

```powershell
# AWS credentials
aws sts get-caller-identity

# Terraform
terraform version

# SSH key
Test-Path kahoot-key.pem

# Docker Hub
docker login
```

---

## 3. Bước 1: Triển Khai Infrastructure

### **3.1. Review Terraform Configuration**

```powershell
cd terraform
terraform init
terraform plan -out=tfplan
```

**Sẽ tạo:**
- 1x Jenkins EC2 (c7i-flex.large) - Jenkins + SonarQube
- 1x K8s EC2 (c7i-flex.large) - k3s + Prometheus + Grafana
- 1x App EC2 (t3.small) - Optional
- VPC, Subnets, Security Groups
- 3x Elastic IPs

**Chi phí:** ~$5-6/day (~$160/month)

### **3.2. Apply Terraform**

```powershell
terraform apply tfplan
```

**Đợi ~10-15 phút** cho user-data scripts chạy xong.

### **3.3. Lấy Outputs**

```powershell
# Jenkins URL
terraform output jenkins_url
# → http://3.217.0.239:8080

# K8s Master IP
terraform output k8s_master_ip
# → 13.57.123.45

# SonarQube URL
terraform output sonarqube_url
# → http://3.217.0.239:9000
```

### **3.4. Kiểm Tra K8s Cluster**

```powershell
# SSH vào K8s master
ssh -i ..\kahoot-key.pem ubuntu@<K8S_IP>

# Xem cluster info
./show-k8s-info.sh

# Xem monitoring stack
./show-monitoring.sh
```

**Expected output:**
```
Kubernetes Cluster Ready!
Nodes: 1
Namespaces: kahoot-clone, monitoring
```

---

## 4. Bước 2: Cấu Hình Jenkins

### **4.1. Lấy Kubeconfig**

```powershell
# Trên local machine
ssh -i kahoot-key.pem ubuntu@<K8S_IP> "sudo cat /etc/rancher/k3s/k3s.yaml" > k8s-config.yaml

# Sửa server URL
(Get-Content k8s-config.yaml) -replace '127.0.0.1', '<K8S_IP>' | Set-Content k8s-config.yaml
```

### **4.2. Thêm Kubeconfig Credential vào Jenkins**

1. Truy cập: http://jenkins_url:8080
2. Login: `admin` / `admin123`
3. Navigate: **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
4. Click: **Add Credentials**
5. Configure:
   - **Kind:** Secret file
   - **File:** Upload `k8s-config.yaml`
   - **ID:** `kubeconfig`
   - **Description:** Kubernetes cluster config
6. Click: **Create**

### **4.3. Verify Jenkins Setup**

Check các credentials có sẵn:
- ✅ `dockerhub-credentials` - Docker Hub
- ✅ `sonarqube-token` - SonarQube
- ✅ `github-credentials` - GitHub
- ✅ `kubeconfig` - K8s cluster (vừa thêm)

---

## 5. Bước 3: Thêm Application Metrics

### **5.1. Install Prometheus Client**

Thêm vào **tất cả** services (gateway, auth, quiz, game, user, analytics):

```powershell
# Gateway
cd services/gateway
npm install prom-client --save

# Auth
cd ../auth-service
npm install prom-client --save

# Quiz
cd ../quiz-service
npm install prom-client --save

# Game
cd ../game-service
npm install prom-client --save

# User
cd ../user-service
npm install prom-client --save

# Analytics
cd ../analytics-service
npm install prom-client --save
```

### **5.2. Tạo Metrics Middleware**

Tạo file `services/gateway/middleware/metrics.js`:

```javascript
const promClient = require('prom-client');

// Create a Registry
const register = new promClient.Registry();

// Add default metrics (CPU, Memory, etc.)
promClient.collectDefaultMetrics({ 
  register,
  prefix: 'nodejs_'
});

// Custom HTTP metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestErrors = new promClient.Counter({
  name: 'http_request_errors_total',
  help: 'Total number of HTTP request errors',
  labelNames: ['method', 'route', 'status_code']
});

// Register custom metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(httpRequestErrors);

// Middleware function
function metricsMiddleware(req, res, next) {
  const start = Date.now();
  
  // Override res.end to capture metrics
  const originalEnd = res.end;
  res.end = function(...args) {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    const labels = {
      method: req.method,
      route: route,
      status_code: res.statusCode
    };
    
    // Record metrics
    httpRequestDuration.observe(labels, duration);
    httpRequestTotal.inc(labels);
    
    if (res.statusCode >= 400) {
      httpRequestErrors.inc(labels);
    }
    
    originalEnd.apply(res, args);
  };
  
  next();
}

module.exports = {
  metricsMiddleware,
  register
};
```

### **5.3. Update Server Files**

**Gateway Service** (`services/gateway/server.js`):

```javascript
const express = require('express');
const { metricsMiddleware, register } = require('./middleware/metrics');

const app = express();

// Apply metrics middleware FIRST (before other routes)
app.use(metricsMiddleware);

// ... existing middleware and routes ...

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
  } catch (err) {
    res.status(500).end(err);
  }
});

// ... rest of your code ...
```

**Lặp lại cho tất cả services:** auth, quiz, game, user, analytics

### **5.4. Thêm Business Metrics (Optional)**

Ví dụ cho User Service:

```javascript
// services/user-service/middleware/metrics.js
const promClient = require('prom-client');

// Business metrics
const activeUsers = new promClient.Gauge({
  name: 'kahoot_active_users',
  help: 'Number of currently active users'
});

const loginAttempts = new promClient.Counter({
  name: 'kahoot_login_attempts_total',
  help: 'Total login attempts',
  labelNames: ['status'] // success, failed
});

const gamesCreated = new promClient.Counter({
  name: 'kahoot_games_created_total',
  help: 'Total number of games created'
});

module.exports = {
  activeUsers,
  loginAttempts,
  gamesCreated
};
```

**Sử dụng trong routes:**

```javascript
const { loginAttempts } = require('../middleware/metrics');

// In login route
router.post('/login', async (req, res) => {
  try {
    // ... login logic ...
    loginAttempts.inc({ status: 'success' });
    res.json({ success: true });
  } catch (error) {
    loginAttempts.inc({ status: 'failed' });
    res.status(401).json({ error: 'Login failed' });
  }
});
```

### **5.5. Update Deployment YAMLs**

Thêm Prometheus annotations vào **tất cả** service deployments:

**gateway-deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway
  namespace: kahoot-clone
spec:
  template:
    metadata:
      labels:
        app: gateway
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "3000"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: gateway
        # ... rest of config ...
```

**Lặp lại cho:** auth, quiz, game, user, analytics (với port tương ứng)

---

## 6. Bước 4: Deploy lên Kubernetes

### **6.1. Commit & Push Code**

```powershell
git add .
git commit -m "feat: Add Prometheus metrics to all services"
git push origin fix/auth-routing-issues
```

### **6.2. Jenkins Tự Động Build**

Jenkins sẽ tự động:
1. ✅ Checkout code
2. ✅ Install dependencies (npm ci)
3. ✅ Run tests
4. ✅ SonarQube analysis
5. ✅ Build Docker images
6. ✅ Push to Docker Hub
7. ✅ Deploy to Kubernetes
8. ✅ Deploy Prometheus & Grafana
9. ✅ Health checks

**Monitor build:** http://jenkins_url:8080/job/kahoot-clone/

### **6.3. Verify Deployment**

```powershell
# SSH vào K8s master
ssh -i kahoot-key.pem ubuntu@<K8S_IP>

# Check all pods
kubectl get pods -n kahoot-clone
kubectl get pods -n monitoring

# Check services
kubectl get svc -n kahoot-clone
kubectl get svc -n monitoring

# Check if metrics endpoints work
kubectl port-forward -n kahoot-clone svc/gateway 3000:3000
# Visit: http://localhost:3000/metrics
```

**Expected output:**
```
NAME                               READY   STATUS    RESTARTS   AGE
gateway-xxxxxxxxx-xxxxx            1/1     Running   0          2m
auth-service-xxxxxxxxx-xxxxx       1/1     Running   0          2m
quiz-service-xxxxxxxxx-xxxxx       1/1     Running   0          2m
game-service-xxxxxxxxx-xxxxx       1/1     Running   0          2m
user-service-xxxxxxxxx-xxxxx       1/1     Running   0          2m
analytics-service-xxxxxxxxx-xxxxx  1/1     Running   0          2m
frontend-xxxxxxxxx-xxxxx           1/1     Running   0          2m

NAME                READY   STATUS    RESTARTS   AGE
prometheus-xxxxx    1/1     Running   0          2m
grafana-xxxxx       1/1     Running   0          2m
```

---

## 7. Bước 5: Cấu Hình Grafana

### **7.1. Truy Cập Grafana**

```
URL: http://<K8S_IP>:30300
Username: admin
Password: admin123
```

### **7.2. Verify Prometheus Datasource**

1. Navigate: **Configuration** → **Data sources**
2. Should see: **Prometheus** (pre-configured)
3. Click: **Test** → Should show "Data source is working"

### **7.3. Import Pre-Built Dashboards**

**Kubernetes Cluster Monitoring:**
1. Click: **+** → **Import**
2. Dashboard ID: `315`
3. Click: **Load**
4. Select datasource: **Prometheus**
5. Click: **Import**

**Kubernetes Pod Monitoring:**
1. Click: **+** → **Import**
2. Dashboard ID: `6417`
3. Click: **Load**
4. Select datasource: **Prometheus**
5. Click: **Import**

**Node Exporter Full:**
1. Click: **+** → **Import**
2. Dashboard ID: `1860`
3. Click: **Load**
4. Select datasource: **Prometheus**
5. Click: **Import**

### **7.4. Tạo Custom Dashboard cho Kahoot Clone**

1. Click: **+** → **Create** → **Dashboard**
2. Click: **Add new panel**

**Panel 1: HTTP Request Rate**
- Query: `rate(http_requests_total[5m])`
- Legend: `{{method}} {{route}}`
- Panel type: Graph
- Title: "HTTP Request Rate"

**Panel 2: HTTP Request Duration**
- Query: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`
- Legend: `{{method}} {{route}}`
- Panel type: Graph
- Title: "95th Percentile Response Time"

**Panel 3: Error Rate**
- Query: `rate(http_request_errors_total[5m])`
- Legend: `{{method}} {{route}}`
- Panel type: Graph
- Title: "Error Rate (4xx, 5xx)"

**Panel 4: Active Users (if implemented)**
- Query: `kahoot_active_users`
- Panel type: Stat
- Title: "Active Users"

**Panel 5: Games Created**
- Query: `increase(kahoot_games_created_total[1h])`
- Panel type: Stat
- Title: "Games Created (Last Hour)"

3. Click: **Save dashboard**
4. Name: "Kahoot Clone - Application Metrics"

### **7.5. Setup Alerts (Optional)**

**High Error Rate Alert:**
1. Edit panel: "Error Rate"
2. Click: **Alert** tab
3. Condition: `WHEN last() OF query(A) IS ABOVE 10`
4. Configure notification channel (email, slack, etc.)

---

## 8. Bước 6: Monitoring & Troubleshooting

### **8.1. Access Points**

```
Jenkins:     http://<JENKINS_IP>:8080
SonarQube:   http://<JENKINS_IP>:9000
Prometheus:  http://<K8S_IP>:30090
Grafana:     http://<K8S_IP>:30300
Application: http://<K8S_IP>:30xxx (NodePort services)
```

### **8.2. Common Prometheus Queries**

**Pod CPU Usage:**
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="kahoot-clone"}[5m])) by (pod)
```

**Pod Memory Usage:**
```promql
sum(container_memory_working_set_bytes{namespace="kahoot-clone"}) by (pod)
```

**HTTP Request Rate by Service:**
```promql
sum(rate(http_requests_total{namespace="kahoot-clone"}[5m])) by (service)
```

**95th Percentile Latency:**
```promql
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))
```

**Error Rate:**
```promql
sum(rate(http_request_errors_total[5m])) by (service, status_code)
```

### **8.3. Troubleshooting**

**Pods không start:**
```bash
kubectl describe pod <pod-name> -n kahoot-clone
kubectl logs <pod-name> -n kahoot-clone
kubectl get events -n kahoot-clone
```

**Prometheus không scrape metrics:**
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Visit: http://localhost:9090/targets

# Check pod annotations
kubectl get pod <pod-name> -n kahoot-clone -o yaml | grep annotations -A 5
```

**Grafana không hiển thị data:**
- Verify datasource connection
- Check time range (last 5-15 minutes)
- Verify query syntax in Prometheus first

---

## 9. Commands Cheat Sheet

### **Terraform**
```powershell
terraform init                    # Initialize
terraform plan -out=tfplan        # Plan changes
terraform apply tfplan            # Apply changes
terraform destroy                 # Destroy all
terraform output                  # Show outputs
```

### **Kubernetes**
```bash
# Pods
kubectl get pods -n kahoot-clone
kubectl describe pod <pod> -n kahoot-clone
kubectl logs <pod> -n kahoot-clone
kubectl logs <pod> -n kahoot-clone -f  # Follow logs

# Services
kubectl get svc -n kahoot-clone
kubectl describe svc <service> -n kahoot-clone

# Deployments
kubectl get deployments -n kahoot-clone
kubectl rollout status deployment/<name> -n kahoot-clone
kubectl rollout restart deployment/<name> -n kahoot-clone

# Monitoring
kubectl get pods -n monitoring
kubectl logs prometheus-xxx -n monitoring
kubectl logs grafana-xxx -n monitoring

# Port Forward
kubectl port-forward -n kahoot-clone svc/gateway 3000:3000
kubectl port-forward -n monitoring svc/prometheus 9090:9090
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

### **Docker**
```bash
# Build
docker build -t kahoot-clone-gateway:latest ./gateway

# Push
docker tag kahoot-clone-gateway:latest 22521284/kahoot-clone-gateway:v1.0
docker push 22521284/kahoot-clone-gateway:v1.0
```

---

## 📞 **Support & Resources**

- **Prometheus Docs:** https://prometheus.io/docs/
- **Grafana Docs:** https://grafana.com/docs/
- **Kubernetes Docs:** https://kubernetes.io/docs/
- **prom-client NPM:** https://www.npmjs.com/package/prom-client

---

## ✅ **Checklist**

- [ ] Terraform infrastructure deployed
- [ ] Jenkins configured with kubeconfig
- [ ] prom-client installed in all services
- [ ] Metrics middleware added to all services
- [ ] /metrics endpoints working
- [ ] Deployment YAMLs updated with annotations
- [ ] Code committed and pushed
- [ ] Jenkins build successful
- [ ] All pods running
- [ ] Prometheus scraping targets
- [ ] Grafana dashboards imported
- [ ] Custom Kahoot dashboard created
- [ ] Alerts configured (optional)

---

**🎉 Hoàn thành! Hệ thống monitoring đã sẵn sàng!**
