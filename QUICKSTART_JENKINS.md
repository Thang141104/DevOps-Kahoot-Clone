# 🚀 Jenkins CI/CD Pipeline - Quick Reference

## 📋 Tổng Quan Hệ Thống

### Infrastructure đã tạo:
- ✅ **Jenkins Server** (c7i-flex.large) - Port 8080
- ✅ **Kubernetes Cluster** (k3s) - Port 6443  
- ✅ **Docker Registry** - Registry 22521284
- ❌ **KHÔNG CÓ SonarQube** (đã loại bỏ)
- ❌ **KHÔNG CÓ App Server** (chỉ dùng K8s)

### AWS Credentials Required:
```
Access Key ID: YOUR_AWS_ACCESS_KEY_ID
Secret Access Key: YOUR_AWS_SECRET_ACCESS_KEY
Region: us-east-1
```

⚠️ Get from AWS IAM Console. Never commit to git!

## 🎯 CI/CD Pipeline Stages

1. **Checkout** - Clone code từ GitHub
2. **Environment Setup** - Kiểm tra Node, npm, Docker
3. **Install Dependencies** - npm install cho 7 services
4. **Build Docker Images** - Build 7 images
5. **Push to Registry** - Push lên Docker Hub (22521284)
6. **Deploy to K8s** - Deploy lên Kubernetes
7. **Health Check** - Verify deployment

**❌ ĐÃ LOẠI BỎ:**
- ~~SonarQube Analysis~~ (removed for performance)
- ~~Quality Gate~~ (removed)
- ~~Trivy Security Scan~~ (removed for performance)
- ~~Snyk Dependency Scan~~ (removed)

## ☸️ Kubernetes Deployments

### Microservices (7 services):
1. **Gateway** - Port 3000 (NodePort: 30000)
2. **Auth Service** - Port 3001
3. **Quiz Service** - Port 3002
4. **Game Service** - Port 3003
5. **User Service** - Port 3004
6. **Analytics Service** - Port 3005
7. **Frontend** - Port 3006 (NodePort: 30006)

Mỗi service:
- 2 replicas (HA)
- Health checks
- Resource limits
- Auto-restart
- Registry: **22521284** (NOT docker.io)

## 🚀 Bắt Đầu Nhanh

### Bước 1: Deploy Infrastructure
```powershell
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

**Đợi 10-15 phút** cho user-data scripts:
- Jenkins: Cài Docker, setup Jenkins container
- K8s: Cài k3s cluster, setup kubectl

### Bước 2: Chờ Services Khởi Động (5 phút)
```bash
# Lấy thông tin
cd terraform
terraform output
```

Bạn sẽ thấy:
```
jenkins_url = "http://<JENKINS_IP>:8080"
k8s_api_endpoint = "https://<K8S_IP>:6443"
```

### Bước 3: Cấu Hình Jenkins

1. **Truy cập Jenkins**: http://<JENKINS_IP>:8080

2. **Lấy admin password**:
```bash
ssh -i kahoot-key.pem ubuntu@<JENKINS_IP>
docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

3. **Install suggested plugins** + thêm:
   - Docker Pipeline
   - Kubernetes CLI Plugin
   - NodeJS Plugin

4. **Thêm Credentials** (Manage Jenkins → Credentials):

   | ID | Type | Values |
   |---|---|---|
   | `dockerhub-credentials` | Username/Password | Docker Hub login (22521284) |
   | `github-credentials` | Username/Password | GitHub token |
   | `kubeconfig` | Secret File | K8s kubeconfig file |

**❌ KHÔNG CẦN:**
- ~~sonarqube-token~~ (đã loại bỏ SonarQube)
- ~~snyk-token~~ (đã loại bỏ Snyk)

### Bước 4: Get Kubeconfig

```bash
# SSH to K8s server
ssh -i kahoot-key.pem ubuntu@<K8S_IP>

# Get kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml > ~/kubeconfig.yaml
exit

# Download kubeconfig
scp -i kahoot-key.pem ubuntu@<K8S_IP>:~/kubeconfig.yaml ./kubeconfig.yaml

# Update IP trong file
# Thay 127.0.0.1 thành <K8S_PUBLIC_IP>
```

Upload file này làm Jenkins credential ID: `kubeconfig`

### Bước 5: Tạo Jenkins Pipeline

1. Jenkins → **New Item** → Tên: `kahoot-clone-pipeline`
2. Chọn **Pipeline** → OK
3. Configure:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository**: https://github.com/Thang141104/DevOps-Kahoot-Clone.git
   - **Credentials**: Chọn `github-credentials`
   - **Branch**: `*/fix/auth-routing-issues` hoặc `*/main`
   - **Script Path**: `Jenkinsfile`
4. **Build Triggers**:
   - ☑️ **GitHub hook trigger for GITScm polling**
5. **Save**

### Bước 6: Cấu hình GitHub Webhook

1. GitHub → Repository **Settings** → **Webhooks** → **Add webhook**
2. Configure:
   - **Payload URL**: `http://<JENKINS_IP>:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Just the push event
3. Click **Add webhook**

### Bước 7: Build!

Click **Build Now** và theo dõi pipeline!

## 📊 Monitoring & Access

### Jenkins Dashboard
```
URL: http://<JENKINS_IP>:8080
- Build history
- Console output
- Artifacts (nếu có)
```

### Kubernetes Monitoring
```
Prometheus: http://<K8S_IP>:30090
Grafana:    http://<K8S_IP>:30300 (admin/admin)
```

### Application Access (sau khi deploy)
```
Frontend: http://<K8S_IP>:30006
Gateway:  http://<K8S_IP>:30000
```

### Kubernetes Commands
```bash
# SSH to K8s server
ssh -i kahoot-key.pem ubuntu@<K8S_IP>

# Check pods
kubectl get pods -n kahoot-clone

# Expected: 14 pods (7 services × 2 replicas)
# All should be Running

# Check services
kubectl get svc -n kahoot-clone

# Check logs
kubectl logs <pod-name> -n kahoot-clone -f

# Describe pod (for troubleshooting)
kubectl describe pod <pod-name> -n kahoot-clone
```

## 🔧 Troubleshooting

### Jenkins không start?
```bash
ssh -i kahoot-key.pem ubuntu@<JENKINS_IP>
docker ps -a
docker logs jenkins
docker restart jenkins
```

### Pipeline fail?
1. Kiểm tra Jenkins **Console Output**
2. Kiểm tra credentials:
   - `dockerhub-credentials` (username: 22521284)
   - `github-credentials`
   - `kubeconfig`
3. Kiểm tra Jenkinsfile syntax

### K8s pods không start?
```bash
kubectl describe pod <pod-name> -n kahoot-clone
kubectl logs <pod-name> -n kahoot-clone

# Check events
kubectl get events -n kahoot-clone --sort-by='.lastTimestamp'
```

### Docker images không pull được?
Kiểm tra registry trong K8s deployment YAMLs:
```yaml
image: 22521284/kahoot-clone-auth:latest  # ✅ ĐÚNG
# NOT: docker.io/kahoot-clone-auth:latest  # ❌ SAI
```

### Environment variables không đúng?
Chạy validation script:
```bash
bash scripts/validate-env-vars.sh
```

Hoặc kiểm tra K8s secrets:
```bash
kubectl get secret app-secrets -n kahoot-clone -o yaml
kubectl get configmap app-config -n kahoot-clone -o yaml
```

## 📁 Files Quan Trọng

```
✅ Jenkinsfile                     - Pipeline definition
✅ terraform/*.tf                  - Infrastructure as Code
✅ k8s/*.yaml                      - Kubernetes manifests (10 files)
✅ docker-compose.yml              - Local development
✅ ENVIRONMENT_VARIABLES_GUIDE.md  - Env vars automation guide
✅ POST_DEPLOYMENT_GUIDE.md        - Full deployment guide
```

## 🎓 Điểm Nổi Bật

### Architecture
- ✅ **2 EC2 instances only**: Jenkins + K8s (NO App Server)
- ✅ **Kubernetes-only deployment**: All microservices on K8s
- ✅ **Single Docker registry**: 22521284 for all images
- ✅ **Auto-generated secrets**: From Terraform to K8s
- ❌ **NO SonarQube**: Removed for performance
- ❌ **NO Trivy/Snyk**: Removed for performance

### DevOps Best Practices
- ✅ Infrastructure as Code (Terraform)
- ✅ Declarative pipelines (Jenkinsfile)
- ✅ GitOps workflow
- ✅ Container orchestration (K8s)
- ✅ High availability (2 replicas per service)
- ✅ Health checks & auto-restart
- ✅ Resource limits
- ✅ Monitoring (Prometheus + Grafana)

### CI/CD Features
- ✅ Automated build → test → deploy
- ✅ Docker multi-stage builds
- ✅ Parallel builds (faster)
- ✅ GitHub webhook integration
- ✅ Rollback support (K8s)
- ✅ Zero-downtime deployment

## 🎉 Kết Quả Mong Đợi

Sau khi setup xong:
1. ✅ Jenkins pipeline tự động build/deploy
2. ✅ Docker images build với registry 22521284
3. ✅ Deploy tự động lên Kubernetes
4. ✅ 7 microservices chạy HA (14 pods total)
5. ✅ Monitoring với Prometheus + Grafana
6. ✅ Application truy cập qua NodePort 30006
7. ❌ **NO SonarQube, NO Trivy** (streamlined pipeline)

## 📞 Pipeline Duration

Expected build time:
- Checkout: ~5s
- Environment Setup: ~2s
- Install Dependencies: ~30s
- Build Docker Images: ~2m
- Push Images: ~1m
- Deploy to K8s: ~3m
- **Total**: ~6-7 minutes

---

**Version:** 2.0.0  
**Updated:** December 2025  
**Platform:** AWS + Jenkins + Kubernetes (K8s-only, NO SonarQube/Trivy)
