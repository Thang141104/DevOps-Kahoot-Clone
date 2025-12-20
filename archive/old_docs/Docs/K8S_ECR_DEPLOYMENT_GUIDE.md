# Kubernetes tự động deploy từ ECR trong Jenkins

## 🎯 Tổng quan

Hệ thống hiện tại đã được cấu hình để **tự động deploy từ ECR lên Kubernetes** thông qua Jenkins pipeline với luồng sau:

```
┌──────────────────────────────────────────────────────────┐
│           JENKINS CI/CD PIPELINE                          │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  1. BUILD & PUSH TO ECR                                   │
│     ├─ Build Docker images với BuildKit cache            │
│     ├─ Tag images: latest + build_number                 │
│     └─ Push lên ECR registry                             │
│        └─> 802346121373.dkr.ecr.ap-southeast-1.amazonaws.com
│                                                           │
│  2. SCAN IMAGES (Trivy)                                   │
│     ├─ Scan vulnerabilities trong images                 │
│     └─ Report CRITICAL/HIGH issues                       │
│                                                           │
│  3. DEPLOY TO KUBERNETES                                  │
│     ├─ Update image tags trong deployments               │
│     ├─ kubectl set image deployment/service               │
│     ├─ kubectl rollout restart (force pull new image)    │
│     └─ kubectl rollout status (verify success)           │
│                                                           │
│  4. VERIFY DEPLOYMENT                                     │
│     ├─ Check pod status                                  │
│     ├─ Check service endpoints                           │
│     └─ Display dashboard URLs                            │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

## 🔧 Cấu hình hiện tại

### 1. ECR Registry Configuration

**Jenkinsfile:**
```groovy
environment {
    AWS_REGION = 'ap-southeast-1'
    AWS_ACCOUNT_ID = '802346121373'
    ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    
    PROJECT_NAME = 'kahoot-clone'
    BUILD_VERSION = "${env.BUILD_NUMBER}"
}
```

**7 ECR Repositories:**
- kahoot-clone-gateway
- kahoot-clone-auth
- kahoot-clone-user
- kahoot-clone-quiz
- kahoot-clone-game
- kahoot-clone-analytics
- kahoot-clone-frontend

### 2. Kubernetes Deployment Files

**Tất cả K8s deployments đã cấu hình sử dụng ECR:**

**k8s/gateway-deployment.yaml:**
```yaml
spec:
  containers:
  - name: gateway
    image: 802346121373.dkr.ecr.ap-southeast-1.amazonaws.com/kahoot-clone-gateway:latest
    imagePullPolicy: Always  # ← Luôn pull image mới nhất
```

**k8s/auth-deployment.yaml:**
```yaml
spec:
  containers:
  - name: auth-service
    image: 802346121373.dkr.ecr.ap-southeast-1.amazonaws.com/kahoot-clone-auth:latest
    imagePullPolicy: Always
```

**Tương tự cho:** user, quiz, game, analytics, frontend

### 3. Jenkins Pipeline Stages

#### Stage 1: Build & Push to ECR

**Jenkinsfile (lines 200-300):**
```groovy
stage('🐳 Docker Build & Push - Batch 1') {
    parallel {
        stage('Gateway') {
            steps {
                sh """
                    docker buildx build \
                      --cache-from ${ECR_REGISTRY}/${PROJECT_NAME}-gateway:latest \
                      --cache-to type=inline \
                      -t ${ECR_REGISTRY}/${PROJECT_NAME}-gateway:${BUILD_VERSION} \
                      -t ${ECR_REGISTRY}/${PROJECT_NAME}-gateway:latest \
                      --push \
                      -f gateway/Dockerfile gateway/
                """
            }
        }
        stage('Auth Service') {
            steps {
                sh """
                    docker buildx build \
                      -t ${ECR_REGISTRY}/${PROJECT_NAME}-auth:${BUILD_VERSION} \
                      -t ${ECR_REGISTRY}/${PROJECT_NAME}-auth:latest \
                      --push \
                      -f services/auth-service/Dockerfile services/auth-service/
                """
            }
        }
        // ... 5 services khác
    }
}
```

**Kết quả:**
- Images được build với 2 tags: `latest` và `build_number` (VD: `42`)
- Tự động push lên ECR
- BuildKit cache để build nhanh hơn

#### Stage 2: Deploy to Kubernetes

**Jenkinsfile (lines 430-480):**
```groovy
stage('🚀 Deploy to Kubernetes') {
    steps {
        script {
            echo "📦 Deploying to Kubernetes cluster..."
            
            // List of services to deploy
            def services = [
                'gateway',
                'auth-service', 
                'user-service',
                'quiz-service',
                'game-service',
                'analytics-service',
                'frontend'
            ]
            
            // Update image tags in deployments
            services.each { service ->
                sh """
                    kubectl set image deployment/${service} \
                        ${service}=${ECR_REGISTRY}/${PROJECT_NAME}-${service}:${BUILD_VERSION} \
                        -n kahoot-clone
                """
            }
            
            // Restart deployments to force pull new images
            sh """
                kubectl rollout restart deployment --all -n kahoot-clone
                kubectl rollout status deployment --all -n kahoot-clone --timeout=5m
            """
            
            // Verify deployments
            sh """
                kubectl get pods -n kahoot-clone
                kubectl get svc -n kahoot-clone
            """
        }
    }
}
```

**Các lệnh kubectl:**

1. **Update image tag:**
   ```bash
   kubectl set image deployment/gateway \
       gateway=802346121373.dkr.ecr.ap-southeast-1.amazonaws.com/kahoot-clone-gateway:42 \
       -n kahoot-clone
   ```

2. **Restart deployment (force pull):**
   ```bash
   kubectl rollout restart deployment --all -n kahoot-clone
   ```

3. **Wait for rollout to complete:**
   ```bash
   kubectl rollout status deployment --all -n kahoot-clone --timeout=5m
   ```

4. **Verify pods:**
   ```bash
   kubectl get pods -n kahoot-clone
   kubectl get svc -n kahoot-clone
   ```

## 🔐 Xác thực ECR với Kubernetes

Kubernetes cần credentials để pull images từ ECR. Có 2 cách:

### Cách 1: IAM Roles for Service Accounts (IRSA) - Recommended

**terraform/iam-ecr.tf:**
```hcl
# IAM Role for K8s nodes to pull from ECR
resource "aws_iam_role" "k8s_ecr_pull" {
  name = "${var.project_name}-k8s-ecr-pull"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach ECR read-only policy
resource "aws_iam_role_policy_attachment" "k8s_ecr_pull" {
  role       = aws_iam_role.k8s_ecr_pull.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Instance profile for K8s nodes
resource "aws_iam_instance_profile" "k8s_nodes" {
  name = "${var.project_name}-k8s-nodes"
  role = aws_iam_role.k8s_ecr_pull.name
}
```

**terraform/k8s-cluster.tf:**
```hcl
resource "aws_instance" "k8s_master" {
  # ...
  iam_instance_profile = aws_iam_instance_profile.k8s_nodes.name
}

resource "aws_instance" "k8s_workers" {
  # ...
  iam_instance_profile = aws_iam_instance_profile.k8s_nodes.name
}
```

**Với IAM Role, K8s nodes tự động có quyền pull từ ECR mà không cần ImagePullSecrets!**

### Cách 2: ImagePullSecrets (Manual)

Nếu không dùng IAM Role, cần tạo secret:

```bash
# 1. Get ECR login token
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin \
  802346121373.dkr.ecr.ap-southeast-1.amazonaws.com

# 2. Create K8s secret from Docker config
kubectl create secret generic ecr-registry-secret \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson \
  -n kahoot-clone

# 3. Add to deployment
spec:
  imagePullSecrets:
  - name: ecr-registry-secret
  containers:
  - name: gateway
    image: 802346121373.dkr.ecr.ap-southeast-1.amazonaws.com/kahoot-clone-gateway:latest
```

**Lưu ý:** ECR login token hết hạn sau 12h, cần cronjob refresh!

## 📋 Quy trình Deploy tự động

### 1. Developer Push Code

```bash
git add .
git commit -m "Update feature"
git push origin main
```

### 2. Jenkins Webhook Trigger

GitHub/GitLab webhook tự động trigger Jenkins build.

**Jenkinsfile:**
```groovy
triggers {
    githubPush()  // Or gitlab()
}
```

### 3. Pipeline Execution

**Timeline:**
```
00:00 - Checkout code & Trivy repo scan (parallel)
01:00 - ECR login
02:00 - Install dependencies & SonarQube scan (parallel)
05:00 - Docker build batch 1 (gateway, auth)
08:00 - Docker build batch 2 (user, quiz)
11:00 - Docker build batch 3 (game, analytics, frontend)
14:00 - Trivy image scans (all 7 images parallel)
16:00 - Deploy to K8s (update + restart)
18:00 - Verify deployment
19:00 - Pipeline complete ✅
```

### 4. Kubernetes Rolling Update

Kubernetes tự động thực hiện **rolling update**:

```
Old Pod (v41)          New Pod (v42)
     ▼                      ▼
┌─────────┐          ┌─────────┐
│ Running │   →→→    │ Pending │
│ Ready   │          │         │
└─────────┘          └─────────┘
     ▼                      ▼
┌─────────┐          ┌─────────┐
│ Running │   →→→    │ Running │
│ Ready   │          │ Starting│
└─────────┘          └─────────┘
     ▼                      ▼
┌─────────┐          ┌─────────┐
│Terminating        │ Running │
│         │          │ Ready   │
└─────────┘          └─────────┘
     ✗                      ✅
```

**K8s strategy:**
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0  # Always maintain availability
      maxSurge: 1        # Allow 1 extra pod during update
```

### 5. Health Checks

Kubernetes chỉ route traffic khi pod sẵn sàng:

```yaml
spec:
  containers:
  - name: gateway
    readinessProbe:
      httpGet:
        path: /health
        port: 3000
      initialDelaySeconds: 10
      periodSeconds: 5
    livenessProbe:
      httpGet:
        path: /health
        port: 3000
      initialDelaySeconds: 30
      periodSeconds: 10
```

## 🎮 Thực hành Deploy

### Test Pipeline

1. **Tạo Jenkins Pipeline:**

```groovy
// Jenkins UI
New Item → Pipeline
Name: kahoot-clone-cicd
Pipeline script from SCM: Git
Repository URL: <your-repo>
Script Path: Jenkinsfile
```

2. **Add Credentials:**

```groovy
// Jenkins → Credentials → Global
1. AWS Credentials (for ECR)
   - Kind: AWS Credentials
   - ID: aws-ecr-credentials
   - Access Key: <from IAM>
   - Secret Key: <from IAM>

2. SonarQube Token
   - Kind: Secret text
   - ID: sonarqube-token
   - Secret: <from SonarQube>
```

3. **Configure kubeconfig:**

```bash
# On Jenkins server
mkdir -p /var/lib/jenkins/.kube

# Copy kubeconfig from K8s master
scp -i jenkins-key.pem ubuntu@<k8s-master-ip>:/home/ubuntu/.kube/config \
  /var/lib/jenkins/.kube/config

# Set ownership
chown jenkins:jenkins /var/lib/jenkins/.kube/config
chmod 600 /var/lib/jenkins/.kube/config
```

4. **Run Build:**

```
Jenkins → kahoot-clone-cicd → Build Now
```

### Monitor Deployment

```bash
# Watch pods update in real-time
watch kubectl get pods -n kahoot-clone

# Check deployment status
kubectl rollout status deployment/gateway -n kahoot-clone

# View pod logs
kubectl logs -f deployment/gateway -n kahoot-clone

# Check which image is running
kubectl get deployment gateway -n kahoot-clone \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Rollback if needed

```bash
# Rollback to previous version
kubectl rollout undo deployment/gateway -n kahoot-clone

# Rollback to specific revision
kubectl rollout history deployment/gateway -n kahoot-clone
kubectl rollout undo deployment/gateway --to-revision=5 -n kahoot-clone
```

## 🔍 Troubleshooting

### Issue 1: ImagePullBackOff

**Triệu chứng:**
```bash
kubectl get pods -n kahoot-clone
NAME                           READY   STATUS             RESTARTS
gateway-xxx                    0/1     ImagePullBackOff   0
```

**Nguyên nhân:**
- K8s không có quyền pull từ ECR
- Image không tồn tại trong ECR
- Image tag sai

**Giải pháp:**

```bash
# 1. Check IAM role attached to K8s nodes
aws ec2 describe-instances --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'

# 2. Verify image exists in ECR
aws ecr describe-images --repository-name kahoot-clone-gateway \
  --region ap-southeast-1

# 3. Check pod events
kubectl describe pod <pod-name> -n kahoot-clone

# 4. Manually pull image on node
ssh ubuntu@<worker-ip>
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin \
  802346121373.dkr.ecr.ap-southeast-1.amazonaws.com
docker pull 802346121373.dkr.ecr.ap-southeast-1.amazonaws.com/kahoot-clone-gateway:latest
```

### Issue 2: Old Image Running

**Triệu chứng:**
- Pipeline success nhưng pod vẫn chạy image cũ

**Nguyên nhân:**
- `imagePullPolicy: IfNotPresent` thay vì `Always`
- Tag `latest` không thay đổi

**Giải pháp:**

```yaml
# k8s/gateway-deployment.yaml
spec:
  containers:
  - name: gateway
    image: 802346121373.dkr.ecr.ap-southeast-1.amazonaws.com/kahoot-clone-gateway:latest
    imagePullPolicy: Always  # ← Force pull mỗi lần restart
```

Hoặc dùng specific version tag:

```groovy
// Jenkinsfile
kubectl set image deployment/gateway \
    gateway=${ECR_REGISTRY}/${PROJECT_NAME}-gateway:${BUILD_VERSION} \
    -n kahoot-clone
```

### Issue 3: Deployment Timeout

**Triệu chứng:**
```
error: timed out waiting for the condition
```

**Nguyên nhân:**
- Image pull quá lâu (>5 min)
- Health check fail
- Resource không đủ

**Giải pháp:**

```bash
# 1. Increase timeout
kubectl rollout status deployment --all -n kahoot-clone --timeout=10m

# 2. Check resource usage
kubectl top nodes
kubectl top pods -n kahoot-clone

# 3. Check pod events
kubectl get events -n kahoot-clone --sort-by='.lastTimestamp'
```

## 📊 Monitoring & Alerts

### Prometheus Metrics

**k8s/gateway-deployment.yaml:**
```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "3000"
  prometheus.io/path: "/metrics"
```

### Slack Notifications

**Jenkinsfile:**
```groovy
post {
    success {
        slackSend(
            color: 'good',
            message: "✅ Build #${BUILD_NUMBER} deployed successfully\nImages: ${BUILD_VERSION}"
        )
    }
    failure {
        slackSend(
            color: 'danger',
            message: "❌ Build #${BUILD_NUMBER} failed\nCheck: ${BUILD_URL}"
        )
    }
}
```

## 🚀 Best Practices

### 1. Use Specific Tags

**Tốt:**
```yaml
image: 802346121373.dkr.ecr.ap-southeast-1.amazonaws.com/kahoot-clone-gateway:42
```

**Tránh:**
```yaml
image: 802346121373.dkr.ecr.ap-southeast-1.amazonaws.com/kahoot-clone-gateway:latest
```

### 2. Configure Resource Limits

```yaml
spec:
  containers:
  - name: gateway
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

### 3. Enable Auto-scaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: gateway-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: gateway
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 4. Implement Canary Deployment

```yaml
# Deployment v1 (90% traffic)
spec:
  replicas: 9

# Deployment v2 (10% traffic)  
spec:
  replicas: 1
```

## 📚 Tài liệu tham khảo

- [Jenkinsfile](Jenkinsfile) - Complete CI/CD pipeline
- [K8s Deployments](k8s/) - All deployment manifests
- [ECR Guide](ECR_GUIDE.md) - ECR setup and configuration
- [Pipeline Optimization](PIPELINE_OPTIMIZATION.md) - Performance tuning
- [SonarQube Architecture](SONARQUBE_ARCHITECTURE.md) - Quality scanning
- [Terraform Ansible Guide](TERRAFORM_ANSIBLE_GUIDE.md) - Infrastructure automation

## ✅ Checklist Deploy

- [ ] Terraform đã tạo ECR repositories
- [ ] IAM roles configured cho K8s nodes
- [ ] Jenkins có AWS credentials
- [ ] Jenkins có kubeconfig
- [ ] K8s deployments dùng ECR images
- [ ] imagePullPolicy: Always
- [ ] Pipeline đã test thành công
- [ ] Health checks configured
- [ ] Resource limits set
- [ ] Monitoring enabled

---

**Tóm lại:** Hệ thống đã được cấu hình hoàn chỉnh để tự động deploy từ ECR lên K8s. Chỉ cần push code, Jenkins sẽ tự động build → push ECR → deploy K8s! 🚀
