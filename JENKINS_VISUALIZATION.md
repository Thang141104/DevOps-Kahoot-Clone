# Jenkins Pipeline Visualization Guide

## 🎨 Overview

Pipeline được tối ưu với:
- ✅ **Blue Ocean UI** - Modern visualization với flow chart
- ✅ **Parallel Stages** - 8 services build đồng thời
- ✅ **Real-time Progress** - Xem progress từng stage
- ✅ **Visual Feedback** - Emoji và colors cho dễ theo dõi

## 📦 Installation

### Option 1: Automated Setup (Recommended)

```powershell
cd D:\DevOps_Lab2\DevOps-Kahoot-Clone\infrastructure
.\setup-jenkins-visualization.ps1
```

Script sẽ tự động:
1. Lấy Jenkins admin password
2. Cài Blue Ocean và các plugins visualization
3. Restart Jenkins
4. Hiển thị links truy cập

### Option 2: Manual Installation

1. **Access Jenkins**: http://44.201.44.17:8080
2. **Login** với initial password:
   ```bash
   ssh -i terraform/keys/kahoot-clone-key.pem ubuntu@44.201.44.17 \
     "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
   ```
3. **Install Plugins**: Manage Jenkins → Manage Plugins → Available
   - Blue Ocean
   - Pipeline Stage View
   - Build Monitor Plugin
   - Dashboard View
   - AnsiColor

4. **Restart Jenkins**: Manage Jenkins → Prepare for Shutdown → Restart

## 🎯 Using Blue Ocean

### Access Blue Ocean UI

```
http://44.201.44.17:8080/blue
```

### Features

#### 1. **Pipeline Visualization**
- Flowchart hiển thị toàn bộ pipeline
- Parallel stages hiển thị cạnh nhau
- Sequential stages hiển thị từ trên xuống

#### 2. **Real-time Progress**
- Progress bar cho mỗi stage
- Thời gian chạy (duration)
- Status: Running, Success, Failed, Skipped

#### 3. **Log Viewer**
- Click vào stage để xem logs
- Logs có ANSI colors (dễ đọc)
- Auto-scroll khi stage đang chạy

#### 4. **Build History**
- Timeline của các builds
- Compare builds
- Artifacts và test results

## 📊 Pipeline Structure

### Current Jenkinsfile Organization

```
Pipeline: Kahoot Clone CI/CD
├─ 🚀 Initialization (Sequential)
│  └─ Checkout code
│
├─ 🔍 Security Scan (Parallel - 2 stages)
│  ├─ Trivy Repository Scan
│  └─ SonarQube Analysis
│
├─ 🔐 ECR Login (Sequential)
│
├─ 📦 Install Dependencies (Parallel - 8 stages)
│  ├─ Gateway
│  ├─ Auth Service
│  ├─ User Service
│  ├─ Quiz Service
│  ├─ Game Service
│  ├─ Analytics Service
│  └─ Frontend
│
├─ 🐳 Build & Push - Batch 1 (Parallel - 4 services)
│  ├─ Gateway Image
│  ├─ Auth Service Image
│  ├─ User Service Image
│  └─ Quiz Service Image
│
├─ 🐳 Build & Push - Batch 2 (Parallel - 4 services)
│  ├─ Game Service Image
│  ├─ Analytics Service Image
│  └─ Frontend Image
│
├─ 🔍 Security Scan Images (Parallel - 7 scans)
│  ├─ Scan Gateway
│  ├─ Scan Auth Service
│  └─ ... (all services)
│
└─ 🚀 Deploy to Kubernetes (Sequential)
   ├─ Update K8s manifests
   └─ Apply deployments
```

### Visual Representation in Blue Ocean

```
[Initialization] ──→ [Security Scan] ──→ [ECR Login] ──→ [Dependencies]
                           ↓                                    ↓
                      ┌─────────┐                         ┌──────────┐
                      │ Trivy   │                         │ Gateway  │
                      │ SonarQ  │                         │ Auth     │
                      └─────────┘                         │ User     │
                                                          │ Quiz     │
                                                          │ Game     │
                                                          │ Analytics│
                                                          │ Frontend │
                                                          └──────────┘
                                                               ↓
    [Build Batch 1] ──→ [Build Batch 2] ──→ [Security Scan] ──→ [Deploy]
         ↓                     ↓                    ↓
    ┌────────┐            ┌────────┐          ┌─────────┐
    │Gateway │            │Game    │          │Scan All │
    │Auth    │            │Analytics│         │Services │
    │User    │            │Frontend │         └─────────┘
    │Quiz    │            └────────┘
    └────────┘
```

## 🎨 Visual Features

### Stage Colors
- 🔵 **Blue** - Running
- 🟢 **Green** - Success
- 🔴 **Red** - Failed
- ⚪ **Gray** - Skipped
- 🟡 **Yellow** - Unstable

### Emojis for Quick Recognition
- 🚀 Initialization
- 🔍 Security/Scanning
- 🔐 Authentication
- 📦 Dependencies/Install
- 🐳 Docker Build
- ☸️ Kubernetes Deploy
- ✅ Success
- ❌ Error
- ⚠️ Warning

## 📈 Performance Monitoring

### Metrics in Blue Ocean

1. **Build Duration**: Total time from start to finish
2. **Stage Duration**: Time per stage
3. **Parallel Efficiency**: Time saved by parallelization
4. **Success Rate**: Percentage of successful builds
5. **Trend Analysis**: Build time over multiple runs

### Example Performance

```
Total Pipeline Duration: 15-20 minutes

Sequential Stages:
  - Initialization: 30s
  - ECR Login: 10s
  - Deploy: 2-3 min

Parallel Stages (Time Saved):
  - Dependencies: 2 min (vs 16 min sequential = 87% faster)
  - Build Batch 1: 3 min (vs 12 min = 75% faster)
  - Build Batch 2: 3 min (vs 12 min = 75% faster)
  - Security Scans: 1 min (vs 7 min = 85% faster)
```

## 🔧 Customization

### Add New Stage

```groovy
stage('🆕 New Stage') {
    steps {
        script {
            echo "📝 Doing something..."
            sh "your-command"
        }
    }
}
```

### Add Parallel Sub-stages

```groovy
stage('🔄 Parallel Tasks') {
    parallel {
        stage('Task 1') {
            steps {
                sh "task1-command"
            }
        }
        stage('Task 2') {
            steps {
                sh "task2-command"
            }
        }
    }
}
```

### Add Stage Timeout

```groovy
stage('⏱️ Timed Stage') {
    options {
        timeout(time: 10, unit: 'MINUTES')
    }
    steps {
        sh "long-running-task"
    }
}
```

## 🎯 Best Practices

### 1. **Stage Naming**
- ✅ Descriptive names with emojis
- ✅ Clear action verbs (Build, Deploy, Test)
- ❌ Avoid generic names (Stage 1, Task A)

### 2. **Parallel Optimization**
- Group similar duration tasks together
- Avoid mixing fast/slow tasks in same parallel block
- Consider memory constraints (t2.small = 2GB RAM)

### 3. **Error Handling**
```groovy
stage('🛡️ Safe Operation') {
    steps {
        script {
            try {
                sh "risky-command"
            } catch (Exception e) {
                echo "⚠️ Error: ${e.message}"
                currentBuild.result = 'UNSTABLE'
            }
        }
    }
}
```

### 4. **Visual Feedback**
```groovy
stage('📊 Status Report') {
    steps {
        script {
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "✅ Build: SUCCESS"
            echo "🐳 Images: 7 pushed to ECR"
            echo "☸️ Deploy: Kubernetes updated"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
    }
}
```

## 🚨 Troubleshooting

### Blue Ocean Not Loading

```bash
# Check Jenkins status
ssh -i terraform/keys/kahoot-clone-key.pem ubuntu@44.201.44.17 \
  "sudo systemctl status jenkins"

# Check logs
ssh -i terraform/keys/kahoot-clone-key.pem ubuntu@44.201.44.17 \
  "sudo tail -f /var/log/jenkins/jenkins.log"
```

### Plugins Not Installing

1. Check internet connectivity from Jenkins server
2. Manually download plugins: http://updates.jenkins.io/download/plugins/
3. Upload via: Manage Jenkins → Manage Plugins → Advanced → Upload Plugin

### Pipeline Not Showing in Blue Ocean

1. Ensure pipeline is defined in Jenkinsfile
2. Use declarative syntax (not scripted)
3. Commit Jenkinsfile to repository
4. Create Pipeline job pointing to repository

## 📚 Additional Resources

- [Blue Ocean Documentation](https://www.jenkins.io/doc/book/blueocean/)
- [Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Best Practices](https://www.jenkins.io/doc/book/pipeline/pipeline-best-practices/)

## 🎉 Next Steps

After setup:
1. ✅ Access Blue Ocean: http://44.201.44.17:8080/blue
2. ✅ Run pipeline and watch visualization
3. ✅ Click on stages to see logs
4. ✅ Check build duration and optimize further
5. ✅ Set up webhooks for automatic builds on git push
