# 📊 Kubernetes Monitoring Guide - Kahoot Clone

> Hướng dẫn monitoring Kubernetes cluster với Prometheus & Grafana

---

## 📋 Tổng Quan

### Architecture (UPDATED - NO App Server, NO SonarQube)

```
┌─────────────────────────────────────────────────────┐
│                    AWS Cloud                         │
├─────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────────┐        ┌─────────────────┐    │
│  │   Jenkins       │        │  K8s Master     │    │
│  │   (Docker)      │        │  + Prometheus   │    │
│  │                 │        │  + Grafana      │    │
│  │  c7i-flex.large │        │  c7i-flex.large │    │
│  └─────────────────┘        └─────────────────┘    │
│         │                            │               │
│         └────────────────────────────┘               │
│                          │                           │
│               ┌──────────┴──────────┐               │
│               ▼                      ▼               │
│        ┌─────────────┐       ┌─────────────┐       │
│        │  Namespace  │       │  Namespace  │       │
│        │kahoot-clone │       │ monitoring  │       │
│        ├─────────────┤       ├─────────────┤       │
│        │ 7 services  │       │• Prometheus │       │
│        │ 2 replicas  │       │• Grafana    │       │
│        │ 14 pods     │       └─────────────┘       │
│        └─────────────┘                              │
└─────────────────────────────────────────────────────┘
```

**❌ REMOVED:**
- App Server (Docker Compose deployment)
- SonarQube
- PostgreSQL

### Monitoring Flow

```
Application Services (7 microservices)
         ↓
    /metrics endpoint (if implemented)
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

## 🚀 Quick Start

### 1. Deploy Infrastructure

```powershell
cd terraform
terraform init
terraform apply -auto-approve
```

**Wait 10-15 minutes** for:
- Jenkins Docker setup
- K8s k3s installation
- Prometheus & Grafana deployment

### 2. Get Access URLs

```powershell
terraform output

# You'll see:
# jenkins_url = "http://<JENKINS_IP>:8080"
# k8s_api_endpoint = "https://<K8S_IP>:6443"
```

Monitoring URLs:
```
Prometheus: http://<K8S_IP>:30090
Grafana:    http://<K8S_IP>:30300
```

### 3. Access Grafana

1. Open: `http://<K8S_IP>:30300`
2. Login:
   - Username: `admin`
   - Password: `admin`
3. Change password when prompted

---

## 📊 Prometheus Setup

Prometheus is **automatically deployed** by Terraform user-data script on K8s master.

### Verify Prometheus

```bash
# SSH to K8s
ssh -i kahoot-key.pem ubuntu@<K8S_IP>

# Check Prometheus pod
kubectl get pods -n monitoring

# Expected output:
# NAME                          READY   STATUS    RESTARTS   AGE
# prometheus-xxxxxxxxxx-xxxxx   1/1     Running   0          10m
# grafana-xxxxxxxxxx-xxxxx      1/1     Running   0          10m
```

### Access Prometheus UI

```
URL: http://<K8S_IP>:30090
```

**Check Targets:**
1. Click **Status** → **Targets**
2. Verify all targets are **UP**
3. Should see:
   - Kubernetes API server
   - Kubelet metrics
   - Node exporter (if installed)
   - Application services (if /metrics implemented)

### Prometheus Configuration

Located at: `/home/ubuntu/app/k8s/prometheus-deployment.yaml`

Key settings:
```yaml
scrape_interval: 15s
evaluation_interval: 15s
scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
```

---

## 📈 Grafana Dashboards

### Default Datasource

Grafana is pre-configured with Prometheus datasource:
```
Name: Prometheus
Type: Prometheus
URL: http://prometheus:9090
Access: Server (Default)
```

### Import Kubernetes Dashboards

**Option 1: Import from Grafana.com**

1. Go to **Dashboards** → **New** → **Import**
2. Enter Dashboard ID:
   - `315` - Kubernetes cluster monitoring
   - `6417` - Kubernetes cluster monitoring (advanced)
   - `8588` - Kubernetes Deployment metrics
   - `747` - Kubernetes Pod metrics
3. Click **Load** → Select Prometheus datasource → **Import**

**Option 2: Create Custom Dashboard**

Example panels:
- **Pod Count**: `count(kube_pod_info{namespace="kahoot-clone"})`
- **CPU Usage**: `rate(container_cpu_usage_seconds_total[5m])`
- **Memory Usage**: `container_memory_usage_bytes`
- **Network I/O**: `rate(container_network_receive_bytes_total[5m])`

---

## 🔍 Monitoring Queries

### Useful PromQL Queries

**Check running pods:**
```promql
count(kube_pod_info{namespace="kahoot-clone"})
```

**Pod status:**
```promql
kube_pod_status_phase{namespace="kahoot-clone"}
```

**Container restarts:**
```promql
rate(kube_pod_container_status_restarts_total{namespace="kahoot-clone"}[5m])
```

**CPU usage by pod:**
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="kahoot-clone"}[5m])) by (pod)
```

**Memory usage by pod:**
```promql
sum(container_memory_usage_bytes{namespace="kahoot-clone"}) by (pod)
```

**Network receive rate:**
```promql
sum(rate(container_network_receive_bytes_total{namespace="kahoot-clone"}[5m])) by (pod)
```

---

## 🎯 Application Metrics (Optional)

If you want to add custom metrics to your microservices:

### 1. Install prom-client (Node.js)

```bash
npm install prom-client
```

### 2. Add Metrics to Service

Example for [auth-service/server.js](auth-service/server.js):

```javascript
const promClient = require('prom-client');

// Create a Registry
const register = new promClient.Registry();

// Enable default metrics
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// Expose /metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

### 3. Update Prometheus Config

Prometheus will auto-discover pods with annotations:
```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "3001"
    prometheus.io/path: "/metrics"
```

This is already in K8s deployment YAMLs if you added annotations.

---

## 🔧 Troubleshooting

### Prometheus không scrape được pods?

**Check 1: Pod annotations**
```bash
kubectl get pod <pod-name> -n kahoot-clone -o yaml | grep prometheus.io
```

Should see:
```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "3001"
prometheus.io/path: "/metrics"
```

**Check 2: Service có /metrics endpoint?**
```bash
kubectl port-forward -n kahoot-clone svc/auth-service 3001:3001
curl http://localhost:3001/metrics
```

**Check 3: Prometheus logs**
```bash
kubectl logs -n monitoring deployment/prometheus
```

### Grafana không connect được Prometheus?

**Check datasource:**
```bash
# SSH to K8s
kubectl get svc -n monitoring

# Should see prometheus service
# NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
# prometheus   ClusterIP   10.43.xxx.xxx   <none>        9090/TCP
```

**Test connection từ Grafana pod:**
```bash
kubectl exec -n monitoring deployment/grafana -- wget -O- http://prometheus:9090/api/v1/status/config
```

### Pods không chạy?

```bash
# Check pod status
kubectl get pods -n kahoot-clone

# Describe pod
kubectl describe pod <pod-name> -n kahoot-clone

# Check logs
kubectl logs <pod-name> -n kahoot-clone

# Check events
kubectl get events -n kahoot-clone --sort-by='.lastTimestamp'
```

---

## 📊 Dashboard Examples

### Kubernetes Overview Dashboard

Create new dashboard with these panels:

**1. Total Pods**
```promql
count(kube_pod_info{namespace="kahoot-clone"})
```
Type: Stat

**2. CPU Usage**
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="kahoot-clone"}[5m])) by (pod)
```
Type: Graph

**3. Memory Usage**
```promql
sum(container_memory_usage_bytes{namespace="kahoot-clone"}) by (pod) / 1024 / 1024
```
Type: Graph

**4. Network Traffic**
```promql
sum(rate(container_network_receive_bytes_total{namespace="kahoot-clone"}[5m])) by (pod) / 1024
```
Type: Graph

---

## 🎯 Alerts (Optional)

### Create Alert Rules

Edit Prometheus config to add alerts:

```yaml
groups:
  - name: kahoot-clone-alerts
    rules:
      - alert: PodDown
        expr: kube_pod_status_phase{namespace="kahoot-clone",phase!="Running"} > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Pod {{ $labels.pod }} is down"
          
      - alert: HighMemoryUsage
        expr: container_memory_usage_bytes{namespace="kahoot-clone"} > 500000000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} high memory usage"
```

---

## 📁 Related Files

```
k8s/prometheus-deployment.yaml    - Prometheus K8s manifest
k8s/grafana-deployment.yaml       - Grafana K8s manifest
terraform/user-data.sh            - Auto-deploys monitoring stack
ENVIRONMENT_VARIABLES_GUIDE.md    - Env vars for services
POST_DEPLOYMENT_GUIDE.md          - Full deployment guide
```

---

## 🎓 Key Points

**✅ What's Deployed:**
- Prometheus on K8s (namespace: monitoring)
- Grafana on K8s (namespace: monitoring)
- 7 microservices (namespace: kahoot-clone)
- 14 pods total (2 replicas each)

**❌ What's NOT Deployed:**
- NO SonarQube (removed)
- NO App Server (removed)
- NO PostgreSQL (removed)

**🔗 Access:**
- Prometheus: `http://<K8S_IP>:30090`
- Grafana: `http://<K8S_IP>:30300`
- Frontend: `http://<K8S_IP>:30006`
- Gateway: `http://<K8S_IP>:30000`

---

**Version:** 2.0.0  
**Updated:** December 2025  
**Platform:** Kubernetes + Prometheus + Grafana (NO SonarQube, NO App Server)
