#  Post-Deployment Guide - Kahoot Clone CI/CD (Kubernetes-Based)

Hướng dẫn chi tiết các bước sau khi chạy `terraform apply` thành công.

**⚠️ QUAN TRỌNG**: 
- Infrastructure này **CHỈ sử dụng Kubernetes** để deploy microservices
- **KHÔNG có App Server** với Docker Compose (đã bị comment out)
- Microservices chạy dưới dạng Kubernetes Pods, KHÔNG phải Docker Compose containers

---

##  **Bước 1: Lấy thông tin Infrastructure**

```bash
cd terraform
terraform output
```

**Lưu lại các thông tin quan trọng:**
- `jenkins_url`: http://<jenkins_ip>:8080
- `k8s_master_ip`: IP của Kubernetes master node
- `jenkins_public_ip`: IP của Jenkins server
- `k8s_api_endpoint`: https://<k8s_ip>:6443

**❌ KHÔNG CÒN:**
- ~~App Server (t3.small instance)~~
- ~~SonarQube URL~~
- ~~Frontend URL trên App Server~~

---

##  **Bước 2: Truy cập Jenkins**

### **2.1. Mở Jenkins UI**
```
URL: http://<jenkins_public_ip>:8080
Username: admin
Password: admin123
```

### **2.2. Kiểm tra plugins đã cài**
Vào: **Manage Jenkins** → **Plugins** → **Installed plugins**

 Cần có:
- Docker Pipeline
- Kubernetes CLI
- Timestamper
- NodeJS
- HTML Publisher
- Workspace Cleanup
- Github

**❌ KHÔNG CẦN:**
- ~~SonarQube Scanner~~ (đã loại bỏ)
- ~~Trivy~~ (đã loại bỏ)

### **2.3. Cấu hình Tools**
Vào: **Manage Jenkins** → **Tools**

#### **NodeJS Installation:**
- Name: `NodeJS 18`
- Version: NodeJS 18.20.8

#### **Docker:**
- Name: `docker`
- Installation root: `/usr/bin`

**❌ KHÔNG CẦN:**
- ~~SonarQube Scanner~~ (đã loại bỏ từ pipeline)

### **2.4. Cấu hình Credentials**
Vào: **Manage Jenkins** → **Credentials** → **System** → **Global credentials**

Tạo các credentials sau:

- Password: Docker Hub access token
- ID: `dockerhub-credentials`

**Tạo Docker Hub Access Token:**
1. Login vào https://hub.docker.com
2. Account Settings → Security → New Access Token
3. Copy token và paste vào Jenkins

#### **b) GitHub (github-credentials)**
- Type: `Username with password`
- Username: GitHub username của bạn
- Password: GitHub Personal Access Token
- ID: `github-credentials`

**Tạo GitHub PAT:**
1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Scopes: `repo`, `admin:repo_hook`

#### **c) Kubeconfig (kubeconfig)**
- Type: `Secret file`
- File: Upload file kubeconfig từ K8s master
- ID: `kubeconfig`

**❌ KHÔNG CẦN:**
- ~~SonarQube Token~~ (SonarQube đã bị loại bỏ)

---

## **Bước 3: Tạo Jenkins Pipeline Job**

### **3.1. Tạo Job mới**
1. **New Item** → Nhập tên: `kahoot-clone-pipeline`
2. Chọn **Pipeline** → Click **OK**

### **3.2. Cấu hình General**
-  **Discard old builds**: 
  - Days to keep: `7`
  - Max # of builds to keep: `10`

### **4.3. Cấu hình Build Triggers**
-  **GitHub hook trigger for GITScm polling** (Trigger tự động khi có push vào GitHub)

> **Lưu ý**: Cần cấu hình webhook trên GitHub (xem bước 10)

### **3.3. Cấu hình Pipeline**
- Definition: `Pipeline script from SCM`
- SCM: `Git`
- Repository URL: `https://github.com/Thang141104/DevOps-Kahoot-Clone.git`
- Credentials: Chọn `github-credentials`
- Branch: `*/fix/auth-routing-issues` (hoặc `*/main`)
- Script Path: `Jenkinsfile`

### **3.4. Save và Build**
1. Click **Save**
2. Click **Build Now** để test

---

##  **Bước 4: Kiểm tra Pipeline chạy thành công**

### **4.1. Xem Console Output**
Click vào build number → **Console Output**

### **4.2. Các stages cần PASS:**

| Stage | Mô tả | Thời gian |
|-------|-------|-----------|
|  Checkout | Clone code từ GitHub | ~5s |
|  Environment Setup | Kiểm tra Node, npm, Docker | ~2s |
|  Install Dependencies | npm ci cho 7 services | ~30s |
|  Security Scanning | Skipped (Trivy not installed) | ~1s |
|  Build Docker Images | Build 7 images | ~2m |
|  Push Images | Push lên Docker Hub (22521284) | ~1m |
|  Deploy to K8s | Deploy 7 services + monitoring | ~3m |
|  Health Check | Kiểm tra pods running | ~30s |

**❌ KHÔNG CÒN:**
- ~~SonarQube Analysis~~
- ~~Quality Gate~~
- ~~Security Scan Images (Trivy)~~

---

##  **Bước 5: Verify Docker Images**

### **5.1. Kiểm tra images đã build**
SSH vào Jenkins server:
```bash
ssh -i kahoot-key.pem ubuntu@<jenkins_public_ip>
docker exec -it jenkins bash
docker images | grep 22521284
```

Bạn sẽ thấy 7 images với registry `22521284`:
```
22521284/kahoot-clone-gateway:latest
22521284/kahoot-clone-auth:latest
22521284/kahoot-clone-quiz:latest
22521284/kahoot-clone-game:latest
22521284/kahoot-clone-user:latest
22521284/kahoot-clone-analytics:latest
22521284/kahoot-clone-frontend:latest
```

### **5.2. Xem trên Docker Hub**
1. Login vào https://hub.docker.com
2. Repositories → Xem 7 images đã được push

---

##  **Bước 6: Deploy lên Kubernetes**

### **6.1. Automatic Deployment (via Jenkins)**
Jenkins sẽ tự động deploy lên K8s khi pipeline chạy thành công:
1.  Apply namespace, configmap, secrets
2.  Deploy 7 microservices
3.  Deploy Prometheus + Grafana
4.  Wait for rollout completion

### **6.2. Manual Deployment (nếu cần)**
SSH vào K8s master:
```bash
ssh -i kahoot-key.pem ubuntu@<k8s_master_ip>

# Repo đã được clone bởi user-data.sh
cd /home/ubuntu/app

# Apply Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml  # Auto-generated từ Terraform
kubectl apply -f k8s/

# Deploy monitoring stack
kubectl apply -f k8s/prometheus-deployment.yaml
kubectl apply -f k8s/grafana-deployment.yaml
```

### **6.3. Kiểm tra deployment**
SSH vào K8s master:
```bash
ssh -i kahoot-key.pem ubuntu@<k8s_master_ip>

# Xem tất cả pods
kubectl get pods --all-namespaces

# Xem pods của application
kubectl get pods -n kahoot-clone

# Xem services
kubectl get services -n kahoot-clone

# Xem logs
kubectl logs -f deployment/gateway -n kahoot-clone
```

**Kết quả mong đợi:**
```
NAMESPACE       NAME                                 READY   STATUS    
kahoot-clone    gateway-xxx-xxx                      2/2     Running
kahoot-clone    auth-service-xxx-xxx                 2/2     Running
kahoot-clone    quiz-service-xxx-xxx                 2/2     Running
kahoot-clone    game-service-xxx-xxx                 2/2     Running
kahoot-clone    user-service-xxx-xxx                 2/2     Running
kahoot-clone    analytics-service-xxx-xxx            2/2     Running
kahoot-clone    frontend-xxx-xxx                     2/2     Running
monitoring      prometheus-xxx-xxx                   1/1     Running
monitoring      grafana-xxx-xxx                      1/1     Running
```

---

##  **Bước 7: Truy cập Application**

### **7.1. Lấy service URLs**
```bash
kubectl get services -n kahoot-clone
```

### **7.2. Truy cập Frontend qua NodePort**
```
http://<K8s-Master-IP>:30006
```

### **7.3. Truy cập các services**
```bash
# Gateway API
http://<K8s-Master-IP>:30000

# Prometheus
http://<K8s-Master-IP>:30090

# Grafana
http://<K8s-Master-IP>:30300
Username: admin
Password: admin123
```

**❌ KHÔNG CÒN App Server:**
- ~~http://<App-Server-IP>:3006~~ (đã loại bỏ)
- Application CHỈ chạy trên Kubernetes

---

##  **Bước 8: Monitoring & Logs**

### **8.1. Jenkins Logs**
```
http://<jenkins_ip>:8080/job/kahoot-clone-pipeline/<build_number>/console
```

### **8.2. Prometheus**
```
URL: http://<k8s_ip>:30090
```
- Targets: Status → Targets (xem services được scrape)
- Queries: Graph → Execute queries

### **8.3. Grafana Dashboards**
```
URL: http://<k8s_ip>:30300
Username: admin
Password: admin123
```

**Import dashboards:**
1. Dashboard → Import
2. Import IDs:
   - **315**: Kubernetes cluster monitoring
   - **6417**: Kubernetes Cluster Metrics
   - **1860**: Node Exporter
   - **Custom**: KUBERNETES_MONITORING_GUIDE.md có dashboard cho Kahoot services

### **8.4. Kubernetes Logs**
```bash
# Xem tất cả pods
kubectl get pods -n kahoot-clone

# Logs của pod cụ thể
kubectl logs -f <pod-name> -n kahoot-clone

# Events
kubectl get events -n kahoot-clone
```

---

##  **Bước 9: Troubleshooting**

### **Vấn đề 1: Images pull failed (ImagePullBackOff)**
**Lỗi**: `ImagePullBackOff` hoặc `ErrImagePull`

**Nguyên nhân**: Registry không đúng hoặc image chưa được push

**Giải pháp**:
```bash
# Kiểm tra image có tồn tại trên Docker Hub
docker pull 22521284/kahoot-clone-gateway:latest

# Kiểm tra deployment YAML
kubectl describe deployment gateway -n kahoot-clone | grep Image

# Expected: 22521284/kahoot-clone-gateway:latest
# NOT: docker.io/kahoot-clone-gateway:latest
```

### **Vấn đề 2: Pods CrashLoopBackOff**
### **Vấn đề 2: Pods CrashLoopBackOff**
**Lỗi**: Container restarts continuously

**Giải pháp**:
```bash
# Check logs
kubectl logs -f <pod-name> -n kahoot-clone

# Common causes:
# - Missing env vars: Check ConfigMap and Secrets
# - Wrong MongoDB URI: Verify k8s/secrets.yaml
# - Invalid JWT secret
# - Service dependency issues
```

### **Vấn đề 3: Không push được images lên Docker Hub**
**Lỗi**: `unauthorized` khi push lên Docker Hub

**Giải pháp**:
1. Kiểm tra credential `dockerhub-credentials` trong Jenkins
2. Đảm bảo Docker Hub token còn valid
3. Kiểm tra username: `22521284` (KHÔNG phải docker.io)

### **Vấn đề 4: Environment variables không match**
**Lỗi**: Services không connect được với MongoDB

**Giải pháp**:
```bash
# Run validation script
./scripts/validate-env-vars.sh
k8s_instance_type = "c7i-flex.xlarge"
```

Sau đó:
```bash
terraform apply
```

---

##  **Checklist hoàn thành**

### **Infrastructure**
- [ ] Terraform apply thành công (10 resources created)
- [ ] **KHÔNG có App Server** (đã comment out)
- [ ] Jenkins accessible tại http://<jenkins_ip>:8080
- [ ] K8s cluster ready (kubectl get nodes)

### **Jenkins Configuration**
- [ ] Pipeline job được tạo: `kahoot-clone-pipeline`
- [ ] Credentials đã cấu hình:
  - [ ] dockerhub-credentials (username: 22521284)
  - [ ] github-credentials
  - [ ] kubeconfig
- [ ] **KHÔNG CẦN SonarQube token** (đã loại bỏ)
- [ ] GitHub webhook đã được cấu hình
- [ ] Webhook test thành công (status 200)

### **Pipeline Execution**  
- [ ] Build đầu tiên chạy thành công
- [ ] Docker images được build (7 images)
- [ ] **KHÔNG có SonarQube analysis** (skipped)
- [ ] **KHÔNG có Trivy scans** (skipped)
- [ ] Images được push lên Docker Hub (22521284)
- [ ] Application được deploy lên K8s

### **Kubernetes Deployment**
- [ ] Namespace kahoot-clone created
- [ ] ConfigMap và Secrets applied
- [ ] 7 microservices pods running (2 replicas each)
- [ ] Prometheus deployed (namespace: monitoring)
- [ ] Grafana deployed (namespace: monitoring)
- [ ] Frontend accessible từ browser

### **Verification**
- [ ] `kubectl get pods --all-namespaces` shows all pods running
- [ ] Frontend: http://<k8s_ip>:30006
- [ ] Prometheus: http://<k8s_ip>:30090
- [ ] Grafana: http://<k8s_ip>:30300
- [ ] Jenkins accessible tại http://<ip>:8080
- [ ] SonarQube accessible tại http://<ip>:9000
- [ ] Pipeline job được tạo
- [ ] Tất cả credentials đã cấu hình
- [ ] **GitHub webhook đã được cấu hình** ✅
- [ ] **Webhook test thành công (status 200)** ✅
- [ ] Build đầu tiên chạy thành công
- [ ] Docker images được build thành công (7 services)
- [ ] **❌ KHÔNG CÓ** SonarQube analysis (đã loại bỏ)
- [ ] **❌ KHÔNG CÓ** Trivy security scans (đã loại bỏ)
- [ ] Images được push lên Docker Hub (registry 22521284)
- [ ] Application được deploy lên K8s
- [ ] Pods đang running healthy (14 pods total)
- [ ] Frontend accessible từ browser

---

##  **Bước 10: Cấu hình GitHub Webhook** (Bắt buộc)

### **10.1. Truy cập GitHub Repository**
```
https://github.com/Thang141104/DevOps-Kahoot-Clone
```

### **10.2. Thêm Webhook**
1. **Settings** → **Webhooks** → **Add webhook**
2. Cấu hình:
   - **Payload URL**: `http://<jenkins_public_ip>:8080/github-webhook/`
   - **Content type**: `application/json`
   - **SSL verification**: Disable (cho development)
   - **Which events**: Chọn "Just the push event"
   - ☑️ **Active**

3. Click **Add webhook**

### **10.3. Test Webhook**
```bash
# Push test commit
git commit --allow-empty -m "Test webhook trigger"
git push origin fix/auth-routing-issues
```

Jenkins pipeline sẽ tự động chạy sau vài giây!

### **10.4. Xem Webhook Status**
- GitHub → Webhooks → Click vào webhook
- Tab **Recent Deliveries** → Xem response từ Jenkins
- Status 200 = Success ✅

### **10.5. Troubleshooting Webhook**

**Lỗi: Connection timeout**
- Kiểm tra Security Group của Jenkins EC2
- Port 8080 phải allow từ GitHub IPs (0.0.0.0/0)

**Lỗi: 403 Forbidden**
- Kiểm tra Jenkins Security settings
- Manage Jenkins → Security → Enable proxy compatibility

**Lỗi: 404 Not Found**
- URL phải là: `http://<ip>:8080/github-webhook/` (có trailing slash)
- Không được là: `/job/kahoot-clone-pipeline/build`

---

## **Next Steps**

### **1. Infrastructure Summary**
```
✅ Jenkins Server (c7i-flex.large)
   - Port 8080: Web UI
   - Docker: Build images
   - No SonarQube
   
✅ Kubernetes Cluster (c7i-flex.large)  
   - 7 microservices (2 replicas each)
   - Prometheus monitoring
   - Grafana dashboards
   
❌ App Server (REMOVED)
   - No Docker Compose deployment
   - All apps run on Kubernetes
```

### **2. Deployment Flow**
```
GitHub Push
    ↓
GitHub Webhook
    ↓
Jenkins Pipeline
    ↓
├─ Build 7 Docker images
├─ Push to Docker Hub (22521284)
├─ Deploy to Kubernetes
└─ Health check pods
```

### **3. Monitoring Setup**

### **3. Monitoring Setup**
- **Prometheus**: Scrape metrics từ tất cả 7 services
- **Grafana**: Visualize dashboards
- **Documentation**: KUBERNETES_MONITORING_GUIDE.md

### **4. Environment Variables**
- **Single Source of Truth**: terraform.tfvars
- **Auto-generated**: k8s/secrets.yaml from Terraform
- **Validation**: scripts/validate-env-vars.sh
- **Documentation**: ENVIRONMENT_VARIABLES_GUIDE.md

### **5. Security**
- ✅ Secrets stored in K8s Secrets (base64 encoded)
- ✅ ConfigMap for non-sensitive data
- ❌ No SonarQube code analysis (removed for performance)
- ❌ No Trivy security scanning (removed for performance)

### **6. References**
- **Setup**: INSTALLATION.md
- **Monitoring**: KUBERNETES_MONITORING_GUIDE.md
- **Metrics**: METRICS_IMPLEMENTATION.md
- **Env Vars**: ENVIRONMENT_VARIABLES_GUIDE.md
- **Jenkins**: JENKINS_SETUP_COMPLETE.md

---

##  **Support**

Nếu gặp vấn đề:
1. Kiểm tra Jenkins console output
2. Xem K8s pod logs: `kubectl logs -f <pod> -n kahoot-clone`
3. Validate env vars: `./scripts/validate-env-vars.sh`
4. Check pod status: `kubectl describe pod <pod> -n kahoot-clone`
5. Verify images: `docker pull 22521284/kahoot-clone-gateway:latest`

---

** Chúc mừng! CI/CD pipeline (Kubernetes-based) đã sẵn sàng!**

**Architecture Summary:**
- 🔧 Jenkins: CI/CD automation
- ☸️ Kubernetes: Container orchestration
- 📊 Prometheus + Grafana: Monitoring
- 🐳 Docker Hub (22521284): Image registry
- ❌ No App Server, No SonarQube, No Trivy
