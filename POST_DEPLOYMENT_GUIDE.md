# 📋 Post-Deployment Guide - Kahoot Clone CI/CD

Hướng dẫn chi tiết các bước sau khi chạy `terraform apply` thành công.

---

## 🚀 **Bước 1: Lấy thông tin Infrastructure**

```bash
cd terraform
terraform output
```

**Lưu lại các thông tin quan trọng:**
- `jenkins_url`: http://3.217.0.239:8080
- `sonarqube_url`: http://3.217.0.239:9000
- `k8s_master_ip`: IP của Kubernetes master node
- `jenkins_public_ip`: IP của Jenkins server

---

## 🔐 **Bước 2: Truy cập Jenkins**

### **2.1. Mở Jenkins UI**
```
URL: http://<jenkins_public_ip>:8080
Username: admin
Password: admin123
```

### **2.2. Kiểm tra plugins đã cài**
Vào: **Manage Jenkins** → **Plugins** → **Installed plugins**

✅ Cần có:
- Docker Pipeline
- Kubernetes CLI
- SonarQube Scanner
- Timestamper
- NodeJS
- HTML Publisher
- Workspace Cleanup

### **2.3. Cấu hình Tools**
Vào: **Manage Jenkins** → **Tools**

#### **NodeJS Installation:**
- Name: `NodeJS 18`
- Version: NodeJS 18.20.8

#### **SonarQube Scanner:**
- Name: `SonarQube Scanner`
- Version: SonarQube Scanner 5.0.1.3006

#### **Docker:**
- Name: `docker`
- Installation root: `/usr/bin`

### **2.4. Cấu hình Credentials**
Vào: **Manage Jenkins** → **Credentials** → **System** → **Global credentials**

Tạo các credentials sau:

#### **a) Docker Hub (dockerhub-credentials)**
- Type: `Username with password`
- Username: `22521284` (hoặc Docker Hub username của bạn)
- Password: Docker Hub access token
- ID: `dockerhub-credentials`

#### **b) GitHub (github-credentials)**
- Type: `Username with password`
- Username: GitHub username
- Password: GitHub Personal Access Token
- ID: `github-credentials`

#### **c) SonarQube Token (sonarqube-token)**
- Type: `Secret text`
- Secret: SonarQube token (lấy từ bước 3)
- ID: `sonarqube-token`

#### **d) Kubeconfig (kubeconfig)**
- Type: `Secret file`
- File: Upload file kubeconfig từ K8s master
- ID: `kubeconfig`

**Lấy kubeconfig từ K8s master:**
```bash
ssh -i kahoot-key.pem ubuntu@<k8s_master_ip>
cat ~/.kube/config
# Copy nội dung và save vào file local
```

---

## 🔍 **Bước 3: Cấu hình SonarQube**

### **3.1. Truy cập SonarQube**
```
URL: http://<jenkins_public_ip>:9000
Username: admin
Password: admin123
```

**Đổi password ngay lần đầu login!**

### **3.2. Tạo Project**
1. Click **Create Project** → **Manually**
2. Project key: `kahoot-clone`
3. Display name: `Kahoot Clone Microservices`
4. Click **Set Up**

### **3.3. Tạo Token**
1. Vào Administrators
2. Generate token
3. **Copy token** → Dùng cho Jenkins credentials (bước 2.4.c)

### **3.4. Cấu hình SonarQube Server trong Jenkins**
Vào Jenkins: **Manage Jenkins** → **System** → **SonarQube servers**

- Name: `SonarQube`
- Server URL: `http://sonarqube:9000` (Docker service name)
- Token: Chọn credential `sonarqube-token`

---

## 🔨 **Bước 4: Tạo Jenkins Pipeline Job**

### **4.1. Tạo Job mới**
1. **New Item** → Nhập tên: `kahoot-clone-pipeline`
2. Chọn **Pipeline** → Click **OK**

### **4.2. Cấu hình General**
- ✅ **Discard old builds**: 
  - Days to keep: `7`
  - Max # of builds to keep: `10`

### **4.3. Cấu hình Build Triggers**
- ✅ **Poll SCM**: `H/5 * * * *` (Poll GitHub mỗi 5 phút)

### **4.4. Cấu hình Pipeline**
- Definition: `Pipeline script from SCM`
- SCM: `Git`
- Repository URL: `https://github.com/Thang141104/DevOps-Kahoot-Clone.git`
- Credentials: Chọn `github-credentials`
- Branch: `*/fix/auth-routing-issues` (hoặc `*/main`)
- Script Path: `Jenkinsfile`

### **4.5. Save và Build**
1. Click **Save**
2. Click **Build Now** để test

---

## 📊 **Bước 5: Kiểm tra Pipeline chạy thành công**

### **5.1. Xem Console Output**
Click vào build number → **Console Output**

### **5.2. Các stages cần PASS:**

| Stage | Mô tả | Thời gian |
|-------|-------|-----------|
| ✅ Checkout | Clone code từ GitHub | ~5s |
| ✅ Environment Setup | Kiểm tra Node, npm, Docker | ~2s |
| ✅ Install Dependencies | npm ci cho 7 services | ~15s |
| ✅ SonarQube Analysis | Phân tích code quality | ~2m |
| ⚠️ Quality Gate | Chờ SonarQube kết quả | ~30s |
| ✅ Security Scanning | Trivy filesystem scan | ~5s |
| ✅ Build Docker Images | Build 7 images | ~45s |
| ✅ Security Scan Images | Trivy image scans | ~10s |
| ⏭️ Push Images | *Chỉ chạy trên main branch* | ~30s |
| ⏭️ Deploy to K8s | *Chỉ chạy trên main branch* | ~2m |
| ⏭️ Health Check | *Chỉ chạy trên main branch* | ~30s |

### **5.3. Nếu có lỗi SonarQube:**
- Vào SonarQube UI: http://<jenkins_ip>:9000
- Kiểm tra project `kahoot-clone`
- Xem issues/bugs được phát hiện

---

## 🐳 **Bước 6: Verify Docker Images**

### **6.1. Kiểm tra images đã build**
SSH vào Jenkins server:
```bash
ssh -i kahoot-key.pem ubuntu@<jenkins_public_ip>
docker exec -it jenkins bash
docker images | grep kahoot-clone
```

Bạn sẽ thấy 7 images:
```
22521284/kahoot-clone-gateway
22521284/kahoot-clone-auth
22521284/kahoot-clone-quiz
22521284/kahoot-clone-game
22521284/kahoot-clone-user
22521284/kahoot-clone-analytics
22521284/kahoot-clone-frontend
```

### **6.2. Xem Trivy scan reports**
Trong Jenkins UI → Build → **Workspace** → Các file `trivy-*-report.json`

---

## 🚢 **Bước 7: Deploy lên Kubernetes (Main branch)**

### **7.1. Merge code vào main**
```bash
git checkout main
git merge fix/auth-routing-issues
git push origin main
```

### **7.2. Jenkins tự động trigger**
Pipeline sẽ chạy lại và thực hiện:
1. ✅ Push images lên Docker Hub
2. ✅ Deploy lên K8s cluster
3. ✅ Health check pods

### **7.3. Kiểm tra deployment**
SSH vào K8s master:
```bash
ssh -i kahoot-key.pem ubuntu@<k8s_master_ip>

# Xem pods
kubectl get pods -n kahoot-clone

# Xem services
kubectl get services -n kahoot-clone

# Xem logs
kubectl logs -f deployment/gateway -n kahoot-clone
```

---

## 🔍 **Bước 8: Truy cập Application**

### **8.1. Lấy service URLs**
```bash
kubectl get services -n kahoot-clone
```

### **8.2. Truy cập Frontend**
```
http://<K8s-External-IP>:3006
```

### **8.3. Test API Gateway**
```bash
curl http://<K8s-External-IP>:3000/health
```

---

## 📈 **Bước 9: Monitoring & Logs**

### **9.1. Jenkins Logs**
```
http://<jenkins_ip>:8080/job/kahoot-clone-pipeline/<build_number>/console
```

### **9.2. SonarQube Dashboard**
```
http://<jenkins_ip>:9000/dashboard?id=kahoot-clone
```

### **9.3. Kubernetes Logs**
```bash
# Xem tất cả pods
kubectl get pods -n kahoot-clone

# Logs của pod cụ thể
kubectl logs -f <pod-name> -n kahoot-clone

# Events
kubectl get events -n kahoot-clone
```

---

## 🛠️ **Bước 10: Troubleshooting**

### **Vấn đề 1: Pipeline fail ở SonarQube**
**Lỗi**: `out of memory` hoặc `timeout`

**Giải pháp**:
```properties
# File: sonar-project.properties
sonar.javascript.node.maxspace=1536
sonar.exclusions=**/profile.routes.js,**/imageUpload.js
```

### **Vấn đề 2: Không push được images**
**Lỗi**: `unauthorized` khi push lên Docker Hub

**Giải pháp**:
1. Kiểm tra credential `dockerhub-credentials`
2. Đảm bảo Docker Hub token còn valid
3. Kiểm tra username: `22521284`

### **Vấn đề 3: K8s deployment fail**
**Lỗi**: `ImagePullBackOff` hoặc `CrashLoopBackOff`

**Giải pháp**:
```bash
# Describe pod để xem lỗi chi tiết
kubectl describe pod <pod-name> -n kahoot-clone

# Kiểm tra image có tồn tại
docker pull 22521284/kahoot-clone-gateway:latest

# Kiểm tra ConfigMap/Secrets
kubectl get configmap -n kahoot-clone
kubectl get secrets -n kahoot-clone
```

### **Vấn đề 4: Jenkins bị lag/slow**
**Nguyên nhân**: EC2 instance thiếu resource

**Giải pháp**:
```hcl
# terraform/terraform.tfvars
jenkins_instance_type = "c7i-flex.xlarge"  # Nâng từ large lên xlarge
```

Sau đó:
```bash
terraform apply
```

---

## 📝 **Checklist hoàn thành**

- [ ] Jenkins accessible tại http://<ip>:8080
- [ ] SonarQube accessible tại http://<ip>:9000
- [ ] Pipeline job được tạo
- [ ] Tất cả credentials đã cấu hình
- [ ] Build đầu tiên chạy thành công
- [ ] Docker images được build thành công
- [ ] SonarQube analysis hoàn thành
- [ ] Trivy security scans pass
- [ ] Code được merge vào main branch
- [ ] Images được push lên Docker Hub
- [ ] Application được deploy lên K8s
- [ ] Pods đang running healthy
- [ ] Frontend accessible từ browser

---

## 🎯 **Next Steps**

1. **Thêm webhooks** (nếu bạn là owner của repo):
   - GitHub → Settings → Webhooks
   - Payload URL: `http://<jenkins_ip>:8080/github-webhook/`
   - Trigger: Push events

2. **Cấu hình monitoring**:
   - Prometheus + Grafana cho K8s
   - Jenkins monitoring plugins

3. **Setup backup**:
   - Jenkins configuration backup
   - Kubernetes ETCD backup
   - Database backups

4. **Security hardening**:
   - Đổi tất cả default passwords
   - Enable HTTPS với Let's Encrypt
   - Cấu hình firewall rules
   - Restrict SSH access

5. **Performance tuning**:
   - Optimize Docker image sizes
   - Configure K8s resource limits
   - Enable caching trong pipeline

---

## 📞 **Support**

Nếu gặp vấn đề:
1. Kiểm tra Jenkins console output
2. Xem SonarQube analysis logs
3. Kiểm tra K8s pod logs: `kubectl logs -f <pod> -n kahoot-clone`
4. Review Trivy security reports
5. Tham khảo các file README trong project

---

**🎊 Chúc mừng! CI/CD pipeline đã sẵn sàng!**
