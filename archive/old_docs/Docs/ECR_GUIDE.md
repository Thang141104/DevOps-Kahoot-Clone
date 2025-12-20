# 🚀 AWS ECR Integration Guide

## Tại sao sử dụng AWS ECR?

### **So sánh: Docker Hub vs AWS ECR**

| Tiêu chí | Docker Hub | AWS ECR |
|----------|-----------|---------|
| **Tốc độ pull/push từ AWS** | 🐌 Slow (qua Internet) | ⚡ **Very Fast** (cùng VPC/Region) |
| **Chi phí** | 500MB free, $5/tháng cho unlimited | **500MB free**, $0.10/GB/tháng |
| **Bảo mật** | Public/Private | **Private mặc định** + IAM |
| **Build cache** | ❌ Không hỗ trợ tốt | ✅ **BuildKit cache** → tăng tốc 5-10x |
| **Image scanning** | Chỉ có ở paid plan | ✅ **Miễn phí** (scan vulnerabilities) |
| **Tích hợp AWS** | ❌ Cần credentials | ✅ **IAM roles** (không cần password) |

### **Lợi ích khi dùng ECR trên AWS:**

1. ⚡ **Tốc độ cao nhất**
   - Images lưu trong cùng region với EC2/K8s
   - Pull/push qua mạng nội bộ AWS (không tính phí bandwidth)
   - Latency thấp: ~10-50ms thay vì 200-500ms (Docker Hub)

2. 💰 **Tiết kiệm chi phí**
   - 500MB miễn phí mỗi tháng (Free Tier)
   - Chỉ trả $0.10/GB cho storage, $0.09/GB cho transfer
   - Không tính phí khi pull trong cùng region

3. 🔒 **Bảo mật tốt hơn**
   - Private registry mặc định
   - IAM roles → không cần lưu password trong Jenkins
   - Image scanning tự động (phát hiện vulnerabilities)
   - Encryption AES256 miễn phí

4. 🚀 **BuildKit Cache → Tăng tốc rebuild 5-10x**
   - Lần build đầu: ~10 phút
   - Lần build sau (có thay đổi nhỏ): **~2 phút**
   - Cache layers được lưu trong ECR

---

## 📋 Setup Guide

### **Bước 1: Tạo ECR Repositories**

#### **Option 1: PowerShell Script (Khuyến nghị)**

```powershell
# Chạy script tự động
.\setup-ecr.ps1 -Region ap-southeast-1 -ProjectName kahoot-clone

# Hoặc xóa và tạo lại từ đầu
.\setup-ecr.ps1 -Region ap-southeast-1 -DestroyFirst
```

#### **Option 2: Terraform**

```powershell
cd terraform

# Tạo ECR repositories
terraform apply -target=aws_ecr_repository.kahoot_services -auto-approve

# Xem danh sách repositories
terraform output ecr_repositories
```

#### **Option 3: AWS CLI thủ công**

```bash
# Tạo repository cho từng service
services=("gateway" "auth" "user" "quiz" "game" "analytics" "frontend")

for service in "${services[@]}"; do
  aws ecr create-repository \
    --repository-name kahoot-clone-$service \
    --region ap-southeast-1 \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256
done
```

---

### **Bước 2: Cấu hình IAM Role cho Jenkins**

ECR sử dụng IAM roles thay vì username/password → bảo mật hơn!

#### **2.1. Attach IAM Role vào Jenkins EC2**

```bash
# Option 1: Terraform (khuyến nghị)
cd terraform
terraform apply -target=aws_iam_role.jenkins_ecr_role -auto-approve

# Option 2: AWS Console
# 1. Vào EC2 → chọn Jenkins instance
# 2. Actions → Security → Modify IAM role
# 3. Chọn: kahoot-clone-jenkins-role
```

#### **2.2. IAM Policy cần thiết**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### **Bước 3: Cập nhật Jenkinsfile**

#### **3.1. Thay Jenkinsfile hiện tại**

```powershell
# Backup file cũ
Copy-Item Jenkinsfile Jenkinsfile.dockerhub

# Sử dụng Jenkinsfile mới với ECR
Copy-Item Jenkinsfile.ecr Jenkinsfile
```

#### **3.2. Thêm AWS credentials vào Jenkins**

```bash
# SSH vào Jenkins server
ssh -i kahoot-key.pem ubuntu@<jenkins-ip>

# Add credentials
# Jenkins → Manage Jenkins → Credentials → Add Credentials
# - Kind: Secret text
# - Secret: <your-aws-account-id>
# - ID: aws-account-id
```

**Hoặc lấy Account ID tự động:**

```bash
aws sts get-caller-identity --query Account --output text
```

#### **3.3. Update K8s deployments để pull từ ECR**

```yaml
# k8s/gateway-deployment.yaml
spec:
  containers:
  - name: gateway
    image: <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/kahoot-clone-gateway:latest
    imagePullPolicy: Always
```

**Script tự động update:**

```powershell
# Lấy ECR registry URL
$accountId = aws sts get-caller-identity --query Account --output text
$ecrRegistry = "$accountId.dkr.ecr.ap-southeast-1.amazonaws.com"

# Update tất cả deployments
$services = @("gateway", "auth", "user", "quiz", "game", "analytics", "frontend")
foreach ($service in $services) {
    (Get-Content "k8s/$service-deployment.yaml") `
        -replace '22521284/kahoot-clone', "$ecrRegistry/kahoot-clone" `
        | Set-Content "k8s/$service-deployment.yaml"
}
```

---

### **Bước 4: Build & Push đầu tiên**

#### **4.1. Login vào ECR**

```bash
# Jenkins server sẽ tự động login qua IAM role
# Nếu test thủ công:
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com
```

#### **4.2. Build với BuildKit cache**

```bash
# Build lần đầu (slow - ~10 phút)
docker buildx build \
  --cache-to type=inline \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  -t <ecr-registry>/kahoot-clone-gateway:latest \
  --push \
  -f gateway/Dockerfile gateway/

# Build lần sau (fast - ~2 phút)
docker buildx build \
  --cache-from <ecr-registry>/kahoot-clone-gateway:latest \
  --cache-to type=inline \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  -t <ecr-registry>/kahoot-clone-gateway:latest \
  --push \
  -f gateway/Dockerfile gateway/
```

#### **4.3. Chạy Jenkins Pipeline**

```bash
# Jenkins sẽ tự động:
# 1. Login vào ECR qua IAM role
# 2. Build images với BuildKit cache
# 3. Push lên ECR
# 4. Scan vulnerabilities
# 5. Deploy lên K8s
```

---

## 🔧 Cấu hình K8s để pull từ ECR

### **Option 1: IAM Role cho K8s Nodes (Khuyến nghị)**

```bash
# Attach IAM role vào K8s worker nodes
# Terraform đã tạo sẵn: kahoot-clone-k8s-node-role

# Hoặc thủ công:
# 1. EC2 Console → chọn K8s worker nodes
# 2. Actions → Security → Modify IAM role
# 3. Chọn: kahoot-clone-k8s-node-role
```

**IAM Policy cho K8s nodes (chỉ cần pull):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
}
```

### **Option 2: Image Pull Secret (Backup)**

```bash
# Tạo secret trong K8s
kubectl create secret docker-registry ecr-secret \
  --docker-server=<account-id>.dkr.ecr.ap-southeast-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-southeast-1) \
  --namespace=default

# Thêm vào deployment
# imagePullSecrets:
# - name: ecr-secret
```

⚠️ **Lưu ý:** ECR token expires sau 12h → cần cron job để refresh!

---

## 📊 So sánh hiệu suất

### **Build time comparison:**

| Lần build | Docker Hub | ECR (no cache) | ECR (with cache) |
|-----------|------------|----------------|------------------|
| **Build đầu tiên** | ~12 phút | ~10 phút | ~10 phút |
| **Build lần 2 (no change)** | ~11 phút | ~9 phút | **~1 phút** ⚡ |
| **Build lần 3 (nhỏ change)** | ~10 phút | ~8 phút | **~2 phút** ⚡ |

### **Pull time (K8s deployment):**

| Service | Docker Hub | ECR (same region) |
|---------|------------|-------------------|
| Gateway (200MB) | ~45s | **~5s** ⚡ |
| Auth Service (150MB) | ~35s | **~4s** ⚡ |
| Frontend (300MB) | ~60s | **~8s** ⚡ |

**Tổng thời gian deploy 7 services:**
- Docker Hub: ~5 phút
- **ECR: ~30 giây** ⚡

---

## 💰 Chi phí ước tính

### **Storage:**

```
7 services × 200MB average × 10 versions = 14GB
14GB × $0.10/GB = $1.40/tháng
```

### **Transfer (pull từ ECR → K8s trong cùng region):**

```
MIỄN PHÍ (data transfer trong cùng region/AZ)
```

### **Free Tier:**

```
500MB storage miễn phí mỗi tháng
Nếu dùng < 500MB → HOÀN TOÀN MIỄN PHÍ!
```

---

## 🔍 Image Scanning & Security

### **Auto scan khi push:**

```bash
# ECR tự động scan mỗi khi push image mới
# Xem kết quả scan:
aws ecr describe-image-scan-findings \
  --repository-name kahoot-clone-gateway \
  --image-id imageTag=latest \
  --region ap-southeast-1
```

### **Xem vulnerabilities trong Console:**

```
ECR → Repositories → kahoot-clone-gateway → Images → Scan results
```

### **Critical findings:**

```bash
# Get only CRITICAL vulnerabilities
aws ecr describe-image-scan-findings \
  --repository-name kahoot-clone-gateway \
  --image-id imageTag=latest \
  --query 'imageScanFindings.findings[?severity==`CRITICAL`]' \
  --output table
```

---

## 🛠️ Troubleshooting

### **1. ECR login failed**

```bash
# Lỗi: "denied: Your authorization token has expired"
# Giải pháp: Login lại
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin <ecr-registry>
```

### **2. IAM permission denied**

```bash
# Lỗi: "AccessDeniedException: User is not authorized to perform: ecr:GetAuthorizationToken"
# Giải pháp: Attach IAM role có ECR permissions
aws iam attach-role-policy \
  --role-name jenkins-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

### **3. K8s không pull được image**

```bash
# Kiểm tra K8s node có IAM role?
kubectl describe pod <pod-name> | grep "Failed to pull image"

# Giải pháp:
# 1. Attach IAM role vào K8s worker nodes
# 2. Hoặc tạo imagePullSecret
```

### **4. BuildKit cache không hoạt động**

```bash
# Đảm bảo build với:
--cache-from <ecr-registry>/image:latest
--cache-to type=inline
--build-arg BUILDKIT_INLINE_CACHE=1
```

---

## 📚 Tài liệu tham khảo

- [AWS ECR Pricing](https://aws.amazon.com/ecr/pricing/)
- [Docker BuildKit Cache](https://docs.docker.com/build/cache/)
- [ECR IAM Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/security-iam.html)
- [K8s Pull Images from ECR](https://aws.amazon.com/premiumsupport/knowledge-center/eks-ecr-pull-image/)

---

## ✅ Checklist Setup

- [ ] Tạo ECR repositories (7 repos)
- [ ] Attach IAM role vào Jenkins EC2
- [ ] Attach IAM role vào K8s worker nodes
- [ ] Add `aws-account-id` credentials vào Jenkins
- [ ] Replace Jenkinsfile với Jenkinsfile.ecr
- [ ] Update K8s deployments với ECR image URLs
- [ ] Test build & push image đầu tiên
- [ ] Verify image scanning works
- [ ] Test K8s deployment pull từ ECR
- [ ] Monitor storage usage & costs

---

**🚀 Ready to go! Tốc độ rebuild sẽ tăng 5-10x với BuildKit cache!**
