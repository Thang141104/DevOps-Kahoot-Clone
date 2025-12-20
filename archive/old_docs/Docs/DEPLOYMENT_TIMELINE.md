# 🚀 Deployment Timeline

## Overview

Terraform KHÔNG tự động deploy services. Đây là workflow 3 bước:

```
1. Terraform → Tạo infrastructure
2. Jenkins  → Build Docker images
3. K8s      → Deploy services
```

---

## ⏱️ Timeline Chi Tiết

### Step 1: Terraform Apply (~15 phút)

```bash
terraform apply
```

**Tạo:**
- ✅ VPC, Subnets, Internet Gateway
- ✅ Security Groups
- ✅ ECR Repositories (7 repos **RỖNG**)
- ✅ IAM Roles (Jenkins + K8s)
- ✅ Jenkins EC2 (đang cài đặt)
- ✅ K8s Cluster (3 nodes đang init)

**Kết quả:**
- ✅ Infrastructure ready
- ❌ **ECR: EMPTY (không có images)**
- ❌ **Services: NOT RUNNING**

**Tại sao services chưa chạy?**
→ Không có Docker images trong ECR để deploy!

---

### Step 2: Jenkins Build (~15-20 phút lần đầu)

**Chờ Jenkins cài đặt xong (~5 phút):**
```bash
ssh -i kahoot-key.pem ubuntu@<jenkins-ip>
sudo systemctl status jenkins
# Đợi đến khi: active (running)
```

**Setup Jenkins:**
1. Mở: `http://<jenkins-ip>:8080`
2. Lấy password:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
3. Install suggested plugins
4. Create admin user
5. Create Pipeline job:
   - Pipeline from SCM
   - Git: `https://github.com/YOUR_REPO.git`
   - Branch: `fix/auth-routing-issues`
   - Script Path: `Jenkinsfile`

**Run Build:**
6. Click "Build Now"

**Jenkins sẽ:**
- Clone GitHub repo
- `npm install` (7 services)
- `docker build` (7 images từ Dockerfile)
- `docker push` lên ECR

**Timeline:**
- Lần đầu: ~15-20 phút (download dependencies)
- Lần sau: ~3-5 phút (có BuildKit cache)

**Kết quả:**
- ✅ ECR: 7 repositories **CÓ IMAGES**
- ❌ Services: VẪN CHƯA CHẠY (chưa deploy)

---

### Step 3: K8s Deploy (~5-10 phút)

**Chờ K8s cluster ready (~5 phút):**
```bash
ssh -i kahoot-key.pem ubuntu@<k8s-master-ip>
kubectl get nodes
# Đợi đến khi: All nodes Ready
```

**Deploy services:**
```bash
# Clone repo
git clone https://github.com/YOUR_REPO.git
cd DevOps-Kahoot-Clone

# Create namespace & secrets
kubectl apply -f k8s/namespace.yaml

# Create secrets (QUAN TRỌNG!)
kubectl create secret generic app-secrets \
  --from-literal=MONGODB_URI='mongodb+srv://user:pass@cluster.mongodb.net/kahoot' \
  --from-literal=JWT_SECRET='your-super-secret-jwt-key-min-32-chars' \
  --from-literal=EMAIL_USER='your-email@gmail.com' \
  --from-literal=EMAIL_PASSWORD='your-app-password' \
  -n kahoot-clone

# Deploy all services
kubectl apply -f k8s/

# Watch deployment
kubectl get pods -n kahoot-clone -w
```

**K8s sẽ:**
- Pull images từ ECR (nhanh - cùng region)
- Create deployments (7 services)
- Create services (NodePort)
- Start pods

**Timeline:**
- Pull images: ~1-2 phút (tổng 7 services)
- Pods starting: ~3-5 phút

**Kết quả:**
- ✅ **Services RUNNING!**
- ✅ Frontend: `http://<k8s-ip>:30006`
- ✅ Gateway: `http://<k8s-ip>:30000`
- ✅ Prometheus: `http://<k8s-ip>:30090`
- ✅ Grafana: `http://<k8s-ip>:30300`

---

## 📊 Timeline Tổng Hợp

| Thời điểm | Hoạt động | Thời gian | Status |
|-----------|-----------|-----------|---------|
| T=0 | `terraform apply` | 0 min | Starting |
| T=15 | Infrastructure ready | 15 min | ECR rỗng, Services down |
| T=25 | Jenkins ready | +10 min | Cần setup & build |
| T=30 | Jenkins setup done | +5 min | Ready to build |
| T=50 | Jenkins build done | +20 min | Images in ECR |
| T=55 | K8s deploy | +5 min | Services starting |
| **T=60** | **COMPLETE** | **60 min** | **Services UP!** ✅ |

**Lần đầu: ~60 phút**  
**Lần sau (update code): ~10 phút** (Jenkins build + redeploy)

---

## 🤔 Tại Sao Không Tự Động?

### Vấn đề: Chicken-and-Egg

```
Terraform tạo infrastructure
    ↓
ECR repositories (RỖNG)
    ↓
Jenkins cần source code để build
    ↓
Source code trong GitHub (Terraform không access)
    ↓
Cần manual trigger Jenkins build
    ↓
Sau đó mới có images
    ↓
Mới deploy được lên K8s
```

### Terraform KHÔNG THỂ:

- ❌ Clone GitHub repo
- ❌ Run `docker build` trực tiếp
- ❌ Trigger Jenkins job tự động (cần setup Jenkins trước)
- ❌ Deploy lên K8s ngay (chưa có images)

### Giải Pháp Tự Động Hóa (Nâng Cao):

**Option 1: Pre-build images trước terraform**
```bash
# Local build & push trước khi terraform
docker build -t <ecr-registry>/kahoot-clone-auth:latest -f services/auth-service/Dockerfile .
docker push <ecr-registry>/kahoot-clone-auth:latest
# ... (7 services)

# Sau đó mới terraform
terraform apply
```

**Option 2: Terraform provisioner (không khuyến nghị)**
```hcl
resource "null_resource" "trigger_jenkins" {
  depends_on = [aws_instance.jenkins_server]
  
  provisioner "local-exec" {
    command = "curl -X POST http://${aws_instance.jenkins_server.public_ip}:8080/job/kahoot-clone/build"
  }
}
```
→ Vấn đề: Jenkins chưa setup, không có credentials

**Option 3: GitHub Actions + ECR (Khuyến nghị)**
```yaml
# .github/workflows/build-push.yml
on:
  push:
    branches: [main]
    
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v1
      - run: docker build && docker push to ECR
```
→ Tự động build & push mỗi khi commit
→ Terraform chỉ cần deploy infrastructure
→ K8s tự động pull images mới

---

## ✅ Best Practices

### Workflow Hiện Tại (Manual - Lần Đầu):

```
1. terraform apply           → Tạo infrastructure
2. Chờ 10 phút               → Jenkins & K8s init
3. Setup Jenkins manual      → Create pipeline job
4. Click "Build Now"         → Build & push images
5. SSH vào K8s               → kubectl apply
6. Services running!         → Done ✅
```

### Workflow Lần Sau (Update Code):

```
1. git push to GitHub        → New commit
2. Jenkins auto-trigger      → Build & push (3-5 min)
3. kubectl rollout restart   → Update pods (2 min)
4. Services updated!         → Done ✅
```

### Workflow Tương Lai (Full CI/CD):

```
1. git push to GitHub        → Trigger GitHub Actions
2. GitHub Actions            → Build & push to ECR (5 min)
3. ArgoCD/FluxCD            → Auto deploy to K8s (2 min)
4. Services updated!         → Done ✅ (Zero manual)
```

---

## 🔍 Verify Each Step

### After Terraform:
```bash
# Check ECR (should be empty)
aws ecr list-images --repository-name kahoot-clone-auth
# Output: []

# Check Jenkins
curl -I http://<jenkins-ip>:8080
# Should return 403 (Jenkins up but needs auth)

# Check K8s
ssh ubuntu@<k8s-ip> kubectl get nodes
# Should show 3 nodes Ready
```

### After Jenkins Build:
```bash
# Check ECR (should have images)
aws ecr list-images --repository-name kahoot-clone-auth
# Output: [{"imageTag": "latest"}, {"imageTag": "123"}]

# Check image size
aws ecr describe-images --repository-name kahoot-clone-auth
# Should show ~150MB per image
```

### After K8s Deploy:
```bash
# Check pods
kubectl get pods -n kahoot-clone
# All pods should be Running

# Check services
curl http://<k8s-ip>:30006
# Should return frontend HTML

# Check logs
kubectl logs -n kahoot-clone deployment/auth-service
# Should show "Server running on port 3001"
```

---

## 📝 Summary

| Bước | Thời gian | Output | Services Running? |
|------|-----------|--------|-------------------|
| 1. Terraform | 15 min | Infrastructure | ❌ No |
| 2. Jenkins Build | 20 min | Docker images in ECR | ❌ No |
| 3. K8s Deploy | 5 min | Pods running | ✅ **Yes!** |

**Total first-time deployment: ~60 minutes**

**Lần sau chỉ cần:**
- Jenkins build (3-5 min) + K8s update (2 min) = **7 minutes**
