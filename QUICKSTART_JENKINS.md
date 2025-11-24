# 🚀 Jenkins CI/CD Pipeline - Quick Reference

## 📋 Tổng Quan Hệ Thống

### Infrastructure đã tạo:
- ✅ **Jenkins Server** (EC2 t3.medium) - Port 8080
- ✅ **SonarQube** - Port 9000  
- ✅ **Kubernetes Cluster** (k3s) - Port 6443
- ✅ **Docker Registry** - Port 5000
- ✅ **PostgreSQL** - Database cho SonarQube

### AWS Credentials Required:
```
Access Key ID: YOUR_AWS_ACCESS_KEY_ID
Secret Access Key: YOUR_AWS_SECRET_ACCESS_KEY
Region: us-east-1
```

⚠️ Get from AWS IAM Console. Never commit to git!

## 🎯 CI/CD Pipeline Stages

1. **Checkout** - Clone code từ GitHub
2. **Install Dependencies** - npm install cho 7 services
3. **SonarQube Analysis** - Kiểm tra chất lượng code
4. **Quality Gate** - Đảm bảo code đạt tiêu chuẩn
5. **Security Scan** - Trivy + Snyk scan dependencies
6. **Build Docker Images** - Build 7 images
7. **Scan Docker Images** - Security scan images
8. **Push to Registry** - Push lên Docker Hub
9. **Deploy to K8s** - Deploy lên Kubernetes
10. **Health Check** - Verify deployment

## 🔒 Security Tools

### Trivy
- Filesystem vulnerability scanning
- Docker image scanning
- HIGH/CRITICAL severities

### Snyk
- Dependency vulnerability scanning
- Container scanning
- License compliance

### SonarQube
- Code quality analysis
- Security hotspots
- Code coverage
- Technical debt

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

## 🚀 Bắt Đầu Nhanh

### Bước 1: Deploy Infrastructure
```powershell
cd terraform
.\setup-jenkins.ps1
```

### Bước 2: Chờ Services Khởi Động (5 phút)
```bash
# Kiểm tra status
ssh -i kahoot-key.pem ubuntu@<JENKINS_IP>
/home/ubuntu/show-info.sh
```

### Bước 3: Cấu Hình Jenkins

1. **Truy cập Jenkins**: http://<JENKINS_IP>:8080
2. **Lấy password**: Từ /home/ubuntu/show-info.sh
3. **Install plugins**:
   - Docker Pipeline
   - Kubernetes
   - SonarQube Scanner
   - Git, NodeJS

4. **Thêm Credentials** (Manage Jenkins → Credentials):

   | ID | Type | Values |
   |---|---|---|
   | `dockerhub-credentials` | Username/Password | Docker Hub login |
   | `aws-credentials` | AWS Credentials | YOUR_AWS_KEY / YOUR_SECRET |
   | `sonarqube-token` | Secret Text | From SonarQube |
   | `snyk-token` | Secret Text | From snyk.io |
   | `kubeconfig` | Secret File | From K8s server |

### Bước 4: Cấu Hình SonarQube

1. **Truy cập**: http://<JENKINS_IP>:9000
2. **Login**: admin/admin (đổi ngay)
3. **Tạo token**: My Account → Security → Generate Token
4. **Add vào Jenkins**: Manage Jenkins → Configure System → SonarQube

### Bước 5: Get Kubeconfig

```bash
# SSH to K8s server
ssh -i kahoot-key.pem ubuntu@<K8S_IP>
/home/ubuntu/get-kubeconfig.sh

# Download kubeconfig
scp ubuntu@<K8S_IP>:/etc/rancher/k3s/k8s.yaml ./kubeconfig

# Update IP
sed -i 's/127.0.0.1/<K8S_PUBLIC_IP>/g' kubeconfig
```

Upload file này làm Jenkins credential: `kubeconfig`

### Bước 6: Tạo Dockerfiles

```bash
# Run script
bash create-dockerfiles.sh
```

Hoặc tạo thủ công theo template trong JENKINS_CICD_README.md

### Bước 7: Tạo Jenkins Pipeline

1. Jenkins → New Item → **Pipeline**
2. Configure:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository**: https://github.com/Thang141104/DevOps-Kahoot-Clone.git
   - **Branch**: fix/auth-routing-issues
   - **Script Path**: Jenkinsfile
3. Save

### Bước 8: Build!

Click **Build Now** và theo dõi pipeline!

## 📊 Monitoring & Access

### Jenkins Dashboard
```
URL: http://<JENKINS_IP>:8080
- Build history
- Test results  
- Security reports
```

### SonarQube Dashboard
```
URL: http://<JENKINS_IP>:9000
- Code quality
- Security issues
- Coverage
```

### Application Access (sau khi deploy)
```
Frontend: http://<K8S_IP>:30006
Gateway: http://<K8S_IP>:30000
```

### Kubernetes Commands
```bash
# Check pods
kubectl get pods -n kahoot-clone

# Check services
kubectl get svc -n kahoot-clone

# Check logs
kubectl logs <pod-name> -n kahoot-clone

# Describe pod
kubectl describe pod <pod-name> -n kahoot-clone
```

## 🔧 Troubleshooting

### Jenkins không start?
```bash
docker logs jenkins
docker restart jenkins
```

### SonarQube không kết nối?
```bash
docker logs sonarqube
# Đợi thêm 2-3 phút
```

### Pipeline fail?
1. Kiểm tra Jenkins console output
2. Review security scan reports (artifacts)
3. Check credentials trong Jenkins
4. Verify SonarQube connection

### K8s pods không start?
```bash
kubectl describe pod <pod-name> -n kahoot-clone
kubectl logs <pod-name> -n kahoot-clone
```

## 📁 Files Đã Tạo

```
✅ Jenkinsfile                     - Pipeline definition
✅ sonar-project.properties        - SonarQube config
✅ terraform/jenkins-infrastructure.tf - Jenkins & K8s infra
✅ terraform/jenkins-user-data.sh  - Jenkins setup
✅ terraform/k8s-user-data.sh      - K8s setup
✅ k8s/*.yaml                      - K8s manifests (8 files)
✅ JENKINS_CICD_README.md          - Full documentation
✅ create-dockerfiles.sh           - Dockerfile generator
✅ terraform/setup-jenkins.ps1     - Quick setup script
```

## 🎓 Điểm Nổi Bật

### Security
- ✅ Trivy filesystem & image scanning
- ✅ Snyk dependency & container scanning
- ✅ SonarQube security hotspots
- ✅ Secrets in Kubernetes Secrets
- ✅ RBAC enabled

### DevOps Best Practices
- ✅ Infrastructure as Code (Terraform)
- ✅ Declarative pipelines (Jenkinsfile)
- ✅ GitOps workflow
- ✅ Automated testing
- ✅ Quality gates
- ✅ Container orchestration (K8s)
- ✅ High availability (2 replicas)
- ✅ Health checks
- ✅ Resource management

### CI/CD Features
- ✅ Parallel builds (faster)
- ✅ Automated quality checks
- ✅ Security scanning
- ✅ Docker image optimization
- ✅ Blue-green deployment ready
- ✅ Rollback support
- ✅ Monitoring & logging

## 📞 Thông Tin Hỗ Trợ

- **Terraform outputs**: Chạy `terraform output` trong folder terraform
- **Connection info**: Xem file `terraform/CONNECTION_INFO.txt`
- **Full guide**: Đọc `JENKINS_CICD_README.md`

## 🎉 Kết Quả Mong Đợi

Sau khi setup xong:
1. ✅ Jenkins pipeline tự động build/test/deploy
2. ✅ SonarQube phân tích code quality
3. ✅ Trivy & Snyk scan vulnerabilities
4. ✅ Docker images được build và scan
5. ✅ Deploy tự động lên Kubernetes
6. ✅ 7 microservices chạy HA (2 replicas mỗi service)
7. ✅ Application truy cập được qua NodePort

---

**Version:** 1.0.0  
**Created:** November 2025  
**Platform:** AWS + Jenkins + K8s + SonarQube + Trivy + Snyk
