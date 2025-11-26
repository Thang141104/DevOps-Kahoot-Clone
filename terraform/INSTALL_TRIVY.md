# Hướng dẫn cài Trivy vào Jenkins Container

## Cách 1: Sử dụng AWS Console (Session Manager)
1. Truy cập AWS Console → EC2 → Instances
2. Chọn Jenkins instance
3. Click "Connect" → "Session Manager" → "Connect"
4. Chạy lệnh:
```bash
sudo docker exec -u root jenkins bash -c "
  apt-get update && \
  apt-get install -y wget apt-transport-https gnupg lsb-release && \
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - && \
  echo 'deb https://aquasecurity.github.io/trivy-repo/deb \$(lsb_release -sc) main' | tee -a /etc/apt/sources.list.d/trivy.list && \
  apt-get update && \
  apt-get install -y trivy
"
```

## Cách 2: Sử dụng SSH (nếu có key)
```bash
ssh -i your-key.pem ubuntu@3.217.0.239
sudo docker exec -u root jenkins bash -c "
  apt-get update && \
  apt-get install -y wget apt-transport-https gnupg lsb-release && \
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - && \
  echo 'deb https://aquasecurity.github.io/trivy-repo/deb \$(lsb_release -sc) main' | tee -a /etc/apt/sources.list.d/trivy.list && \
  apt-get update && \
  apt-get install -y trivy
"
```

## Cách 3: Tự động (chạy script đã tạo sẵn trong instance)
Script `/home/ubuntu/jenkins-setup.sh` sẽ tự động cài Trivy khi instance khởi động.
Nếu instance đã chạy, SSH vào và chạy:
```bash
sudo /home/ubuntu/jenkins-setup.sh
```

## Kiểm tra Trivy đã cài thành công
```bash
sudo docker exec jenkins trivy --version
```

Kết quả mong đợi:
```
Version: x.x.x
```

## Sau khi cài xong
1. Vào Jenkins → Click "Build Now" để chạy lại pipeline
2. Stage "Security Scanning" sẽ chạy thành công với Trivy
