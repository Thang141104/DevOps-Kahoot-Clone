# Kiểm Tra Phiên Bản Ansible - Version Compatibility Report
**Ngày**: 2025-12-21  
**Trạng thái**: Cần cập nhật

---

## 📋 Phiên Bản Hiện Tại Trong Ansible

### 1. **Java** ✅ PHÙ HỢP
- **Phiên bản**: OpenJDK 17
- **Tệp cấu hình**: `roles/jenkins/tasks/main.yml` line 6
- **Trạng thái**: ✅ Hoạt động, đang được hỗ trợ (LTS)
- **Hết hỗ trợ**: 2029-09
- **Chi tiết**:
  - ✅ SonarQube 11 yêu cầu Java 17+
  - ✅ Jenkins LTS hỗ trợ Java 17
  - ✅ Phù hợp với pipeline hiện tại

### 2. **Node.js** ⚠️ CẬP NHẬT KHUYẾN CÁO
- **Phiên bản**: Node.js 18.x
- **Tệp cấu hình**: `roles/jenkins/tasks/nodejs.yml` line 28
- **Trạng thái**: ⚠️ Still active, nhưng không phải LTS
- **Hết hỗ trợ**: 2025-04-30 (SẮP HẾT)
- **Chi tiết**:
  - ⚠️ Node.js 18 sắp kết thúc hỗ trợ (30 tháng 4, 2025 - 4 tháng nữa)
  - ✅ npm packages vẫn tương thích
  - ⚠️ Nên nâng cấp lên Node.js 20 LTS (hỗ trợ đến 2026-10)
- **Khuyến nghị**: Nâng cấp lên Node.js 20.x

### 3. **SonarQube Scanner** ✅ PHẦN CỨNG CÓ VẤNĐỀ
- **Phiên bản**: 4.8.0.2856
- **Tệp cấu hình**: `roles/jenkins/defaults/main.yml` line 11
- **Trạng thái**: ✅ Hoạt động nhưng cũ
- **Chi tiết**:
  - ✅ Tương thích với Java 17
  - ✅ Tương thích với SonarQube 11
  - ❌ Yêu cầu Java 17 mới được cài (Jenkins hiện có Java 11)
  - ✅ Phiên bản mới: 5.0.1 (2024-10) nhưng cũng yêu cầu Java 17+
- **Vấn đề gặp phải**: 
  ```
  UnsupportedClassVersionError: class file version 61.0
  Jenkins currently has Java 11 (recognizes class file versions up to 55.0)
  ```

### 4. **SonarQube Server** ❌ HẾT HỖ TRỢ (VỪA CẬP NHẬT)
- **Phiên bản cũ**: 10-community
- **Phiên bản mới**: 11-community ✅
- **Tệp cấu hình**: `k8s/sonarqube-deployment.yaml` line 66
- **Trạng thái**: ❌ SonarQube 10 kết thúc hỗ trợ (2025-07)
- **Chi tiết**:
  - ❌ SonarQube 10.x kết thúc hỗ trợ năm 2025
  - ✅ SonarQube 11.x là phiên bản LTS hiện tại
  - ✅ Vừa cập nhật sang sonarqube:11-community
- **Trạng thái cập nhật**: ✅ ĐÃ CẬP NHẬT

### 5. **Jenkins** ✅ PHÙ HỢP
- **Phiên bản**: Latest LTS
- **Repository**: `https://pkg.jenkins.io/debian-stable`
- **Trạng thái**: ✅ Hoạt động, được hỗ trợ
- **Chi tiết**:
  - ✅ Cài đặt từ kho ổn định (stable) - tự động cập nhật
  - ✅ Tương thích với Java 17
  - ✅ Hỗ trợ plugins cần thiết

### 6. **Trivy** ✅ PHÙ HỢP
- **Trạng thái**: ✅ Hoạt động, phiên bản mới nhất
- **Chi tiết**:
  - ✅ Tool quét lỗ hổng bảo mật
  - ✅ Tự động cập nhật latest

### 7. **AWS CLI** ✅ PHÙ HỢP
- **Trạng thái**: ✅ Hoạt động, phiên bản mới nhất
- **Chi tiết**:
  - ✅ Tự động cập nhật latest

### 8. **kubectl** ✅ PHÙ HỢP
- **Trạng thái**: ✅ Hoạt động, phiên bản mới nhất
- **Chi tiết**:
  - ✅ Tự động cập nhật latest

---

## 🔍 Tương Thích Giữa Các Thành Phần

### Vấn đề Chính ❌
```
Jenkins (Java 11) ----❌----> SonarQube Scanner 4.8.0.2856 (yêu cầu Java 17)
                      │
                      └─> UnsupportedClassVersionError: class file version 61.0
```

### Giải Pháp ✅
```
Ansible cài Java 17 ----✅----> SonarQube Scanner 4.8.0.2856
                         │
                         └─> ✅ Hoạt động đúng
```

---

## 📊 Bảng Tương Thích

| Thành Phần | Phiên Bản | Trạng Thái | Hỗ Trợ Đến | Ghi Chú |
|-----------|----------|----------|-----------|---------|
| Java | 17 (Ansible) vs 11 (Hiện tại) | ❌/✅ | 2029-09 | Ansible đúng, Jenkins sai |
| Node.js | 18.x | ⚠️ | 2025-04-30 | Sắp hết, nên upgrade -> 20 |
| SonarQube Scanner | 4.8.0.2856 | ✅ | N/A | Hoạt động nếu Java 17 |
| SonarQube Server | 10 → 11 | ❌→✅ | 2026+ | Vừa cập nhật sang 11 |
| Jenkins | Latest LTS | ✅ | Liên tục | Ổn định |
| Trivy | Latest | ✅ | Liên tục | Ổn định |
| AWS CLI | Latest | ✅ | Liên tục | Ổn định |
| kubectl | Latest | ✅ | Liên tục | Ổn định |

---

## 🚨 Vấn Đề Phát Hiện

### 1. **Java Version Mismatch** ❌ CRITICAL
- **Vấn đề**: Jenkins hiện có Java 11 nhưng Ansible định cài Java 17
- **Tác động**: SonarQube Scanner không chạy được
- **Lỗi**:
  ```
  UnsupportedClassVersionError: class file version 61.0
  this version recognizes class file versions up to 55.0
  ```
- **Giải pháp**:
  ```bash
  # Chạy playbook fix-jenkins-java.yml
  ansible-playbook playbooks/fix-jenkins-java.yml -i inventory/hosts
  ```

### 2. **Node.js 18 Approaching EOL** ⚠️ WARNING
- **Vấn đề**: Node.js 18 kết thúc hỗ trợ 30/04/2025
- **Tác động**: 4 tháng nữa sẽ không có security patches
- **Giải pháp**:
  ```yaml
  # Cập nhật roles/jenkins/tasks/nodejs.yml
  - name: Add Node.js 20 repository
    apt_repository:
      repo: "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x {{ ansible_distribution_release }} main"
  ```

### 3. **SonarQube 10 End of Life** ❌ RESOLVED
- **Vấn đề**: SonarQube 10 kết thúc hỗ trợ 2025
- **Tác động**: Không còn nhận security updates
- **Trạng thái**: ✅ ĐÃ CẬP NHẬT sang SonarQube 11
- **Verify**:
  ```bash
  kubectl apply -f k8s/sonarqube-deployment.yaml
  kubectl rollout restart deployment/sonarqube -n sonarqube
  kubectl get pods -n sonarqube
  ```

---

## ✅ Cần Thực Hiện

### Ngay lập tức (Critical):
1. ✅ **Cập nhật SonarQube 10 → 11** 
   - Đã cập nhật `k8s/sonarqube-deployment.yaml`
   - Cần áp dụng: `kubectl apply -f k8s/sonarqube-deployment.yaml`

2. ❌ **Nâng cấp Java 11 → 17 trên Jenkins**
   - Chạy: `ansible-playbook playbooks/fix-jenkins-java.yml -i inventory/hosts`
   - Hoặc chạy thủ công: `infrastructure/terraform/fix-jenkins-java.sh`

### Trong tương lai gần (Recommended):
3. ⚠️ **Cập nhật Node.js 18 → 20**
   - Cập nhật file: `roles/jenkins/tasks/nodejs.yml`
   - Dự kiến: Trước 2025-04-30

### Xác minh sau cập nhật:
```bash
# Kiểm tra Java
java -version

# Kiểm tra SonarQube Scanner
sonar-scanner --version

# Kiểm tra SonarQube Server
kubectl logs -n sonarqube deployment/sonarqube | grep "SonarQube"

# Kiểm tra Node.js
node --version
```

---

## 📝 Kết Luận

| Tiêu Chí | Kết Quả |
|---------|--------|
| Ansible config có vấn đề? | ✅ Ansible cấu hình đúng (Java 17, Node 18, etc.) |
| Hiện tại hoạt động? | ❌ Không - Java 11 vs 17 mismatch |
| Phù hợp? | ⚠️ Phần lớn phù hợp, nhưng cần fix Java urgently |
| Cần cập nhật? | ✅ SonarQube 10→11 (Done), Node 18→20 (Soon) |

**Trạng thái chung**: **⚠️ Cần sửa ngay Java version để hoạt động bình thường**
