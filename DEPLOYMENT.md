# 🚀 Deployment Guide - Microservices

## 📋 Tổng quan

Có **2 cách deploy** microservices lên Kubernetes cluster:

### 1. ✅ **Tự động qua Jenkins Pipeline** (Khuyến nghị)
### 2. 🛠️ **Manual qua kubectl**

---

## 🎯 Option 1: Deploy qua Jenkins (CI/CD)

### Bước 1: Access Jenkins
```bash
# Jenkins đã được cài đặt tại:
http://44.201.44.17:8080

# Lấy initial password:
ssh -i infrastructure/terraform/keys/kahoot-clone-key.pem ubuntu@44.201.44.17 \
  "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
```

### Bước 2: Cấu hình Jenkins

1. **Install plugins** (nếu chưa có):
   - Git
   - Docker Pipeline
   - Kubernetes CLI
   - AWS Credentials
   - SonarQube Scanner

2. **Add AWS Credentials**:
   - Go to: `Manage Jenkins` → `Credentials` → `Global`
   - Add: `AWS Credentials` với ID: `aws-credentials`
   - Input: AWS Access Key ID và Secret Access Key

3. **Add SonarQube Token**:
   - Add: `Secret text` với ID: `sonarqube-token`

### Bước 3: Tạo Pipeline Job

1. **New Item** → **Pipeline**
2. **Pipeline Definition**: `Pipeline script from SCM`
3. **SCM**: Git
4. **Repository URL**: `https://github.com/Thang141104/DevOps-Kahoot-Clone.git`
5. **Branch**: `*/fix/auth-routing-issues`
6. **Script Path**: `Jenkinsfile`

### Bước 4: Run Pipeline

Click **Build Now** - Pipeline sẽ tự động:
- ✅ Build tất cả Docker images
- ✅ Push lên ECR
- ✅ Scan security với Trivy
- ✅ Code quality với SonarQube
- ✅ Deploy lên Kubernetes cluster

---

## 🛠️ Option 2: Deploy Manual

### Prerequisites

Đảm bảo Kubernetes cluster đã chạy:
```powershell
cd infrastructure
.\deploy.ps1 -Action ansible
```

### Bước 1: Copy kubeconfig

```powershell
# Script sẽ tự động copy kubeconfig từ K8s master
cd infrastructure
.\deploy-services.ps1 -Action all
```

### Bước 2: Tạo Secrets

```powershell
# Copy example file
cd k8s
Copy-Item secrets.yaml.example secrets.yaml

# Sửa secrets.yaml với thông tin thực:
# - MongoDB credentials
# - JWT secrets
# - Email credentials
# - AWS credentials
```

### Bước 3: Deploy tất cả

```powershell
cd infrastructure
.\deploy-services.ps1 -Action all
```

Hoặc từng bước:
```powershell
.\deploy-services.ps1 -Action namespace
.\deploy-services.ps1 -Action secrets
.\deploy-services.ps1 -Action services
.\deploy-services.ps1 -Action test
```

---

## 📊 Kiểm tra Deployment

### Check pods status
```bash
kubectl get pods -n kahoot-clone
```

Expected output:
```
NAME                              READY   STATUS    RESTARTS   AGE
mongodb-0                         1/1     Running   0          5m
gateway-xxxx                      1/1     Running   0          4m
auth-service-xxxx                 1/1     Running   0          4m
user-service-xxxx                 1/1     Running   0          4m
quiz-service-xxxx                 1/1     Running   0          4m
game-service-xxxx                 1/1     Running   0          4m
analytics-service-xxxx            1/1     Running   0          4m
frontend-xxxx                     1/1     Running   0          4m
```

### Check services
```bash
kubectl get svc -n kahoot-clone
```

### View logs
```bash
# Specific pod
kubectl logs -n kahoot-clone <pod-name> -f

# All pods of a deployment
kubectl logs -n kahoot-clone -l app=gateway -f
```

### Troubleshooting
```bash
# Describe pod (xem events)
kubectl describe pod -n kahoot-clone <pod-name>

# Get into pod
kubectl exec -it -n kahoot-clone <pod-name> -- /bin/sh

# Restart deployment
kubectl rollout restart deployment/<deployment-name> -n kahoot-clone
```

---

## 🌐 Access Services

### Option A: NodePort (Đơn giản)
```bash
# Get NodePort
kubectl get svc -n kahoot-clone gateway -o wide

# Access via K8s worker node IP + NodePort
http://<worker-ip>:<nodeport>
```

### Option B: LoadBalancer (AWS)
Sửa service type trong deployment files:
```yaml
spec:
  type: LoadBalancer  # Thay vì NodePort
```

### Option C: Ingress (Khuyến nghị production)
```bash
# Install Nginx Ingress Controller
kubectl apply -f k8s/monitoring/ingress-nginx.yaml

# Apply Ingress rules
kubectl apply -f k8s/ingress.yaml
```

---

## 🔄 Update Services

### Via Jenkins
- Commit code changes
- Push to GitHub
- Jenkins tự động build và deploy

### Manual
```bash
# Rebuild image
docker build -t <image-name> .
docker push <ecr-registry>/<image-name>

# Restart deployment
kubectl rollout restart deployment/<deployment-name> -n kahoot-clone
```

---

## 📝 Deployment Checklist

- [ ] Infrastructure deployed (Terraform + Ansible)
- [ ] Kubernetes cluster running (3 nodes ready)
- [ ] ECR repositories created (7 repos)
- [ ] Jenkins configured with credentials
- [ ] Secrets.yaml configured with real credentials
- [ ] Services deployed to Kubernetes
- [ ] All pods in Running status
- [ ] Services accessible via NodePort/LoadBalancer
- [ ] MongoDB data persistent
- [ ] Monitoring setup (optional)

---

## 🆘 Common Issues

### Pods in ImagePullBackOff
```bash
# Kiểm tra ECR credentials
kubectl get secret -n kahoot-clone
kubectl describe pod -n kahoot-clone <pod-name>

# Solution: Push images to ECR trước
```

### Pods in CrashLoopBackOff
```bash
# Check logs
kubectl logs -n kahoot-clone <pod-name>

# Thường do:
# - Missing environment variables
# - Cannot connect to MongoDB
# - Port conflicts
```

### MongoDB connection issues
```bash
# Check MongoDB pod
kubectl get pod -n kahoot-clone mongodb-0

# Check service
kubectl get svc -n kahoot-clone mongodb

# Test connection from another pod
kubectl exec -it -n kahoot-clone <any-pod> -- nc -zv mongodb 27017
```

---

## 📚 Additional Resources

- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [AWS ECR Docs](https://docs.aws.amazon.com/ecr/)
- [SonarQube Integration](https://docs.sonarqube.org/)
