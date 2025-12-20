# EC2 Resource Requirements Analysis

## ⚠️ Current Configuration vs Requirements

### 📊 Current Setup
```
Jenkins EC2: t3.medium
├─ vCPU: 2 cores
├─ RAM: 4 GB
├─ Network: Up to 5 Gbps
└─ Cost: ~$30/month

K8s Master: t3.medium (2 vCPU, 4 GB RAM)
K8s Workers: 2x t3.medium (2 vCPU, 4 GB RAM each)
```

### 🔥 New Pipeline Requirements

#### Parallel Workloads
```
Stage 1: Checkout + Trivy Repo Scan
├─ Git clone: ~100 MB
└─ Trivy scan: 0.5 GB RAM

Stage 2: 8 Parallel NPM Installs + SonarQube
├─ Gateway: 200 MB RAM
├─ Auth: 200 MB RAM
├─ User: 200 MB RAM
├─ Quiz: 200 MB RAM
├─ Game: 200 MB RAM
├─ Analytics: 200 MB RAM
├─ Frontend: 400 MB RAM (React build)
├─ Shared: 100 MB RAM
└─ SonarQube Scanner: 1 GB RAM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: ~2.9 GB RAM needed

Stage 3: 4 Parallel Docker Builds (Batch 1)
├─ Gateway build: 512 MB RAM
├─ Auth build: 512 MB RAM
├─ User build: 512 MB RAM
└─ Quiz build: 512 MB RAM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: ~2 GB RAM needed

Stage 4: 3 Parallel Docker Builds (Batch 2)
├─ Game build: 512 MB RAM
├─ Analytics build: 512 MB RAM
└─ Frontend build: 1 GB RAM (React)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: ~2 GB RAM needed

Stage 5: 8 Parallel Trivy Scans
├─ 7 image scans: ~200 MB each
└─ Trivy DB cache: 500 MB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: ~1.9 GB RAM needed
```

### 📈 Peak Memory Usage Calculation

```
Base Jenkins:           500 MB
Jenkins JVM:            800 MB
Docker daemon:          500 MB
BuildKit cache:         500 MB
Peak parallel stage:  2,900 MB (NPM + SonarQube)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOTAL REQUIRED:      ~5.2 GB RAM

Available (t3.medium): 4 GB RAM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DEFICIT:             -1.2 GB ❌ INSUFFICIENT!
```

## ⚠️ Risk Assessment

### 🔴 CRITICAL Issues with t3.medium

1. **OOM (Out of Memory) Kills**
   - Parallel npm installs will be killed
   - Docker builds will fail randomly
   - Jenkins will crash during peak load

2. **Swap Thrashing**
   - Severe performance degradation
   - Build time: 15 min → 45+ min
   - Disk wear from constant swapping

3. **Build Failures**
   - Random build failures: ~40% chance
   - "Cannot allocate memory" errors
   - Incomplete Docker images

### 🟡 MEDIUM Issues

4. **CPU Bottleneck**
   - 2 cores for 8 parallel npm installs
   - Each process gets ~12% CPU
   - Context switching overhead

5. **Network Saturation**
   - Parallel ECR push/pull
   - NPM package downloads
   - Git operations

## ✅ Recommended Solutions

### Option 1: Upgrade to t3.large (RECOMMENDED)
```
Instance: t3.large
├─ vCPU: 2 cores
├─ RAM: 8 GB ✅
├─ Cost: ~$60/month (+$30/month)
└─ Headroom: 2.8 GB for caching

Benefits:
✅ Sufficient for all parallel stages
✅ Room for BuildKit cache
✅ No OOM kills
✅ Stable 15-minute builds
```

### Option 2: Reduce Parallelization
```groovy
// In Jenkinsfile - reduce concurrent jobs
PARALLEL_BUILD_JOBS = '2'      // Instead of 4
NPM_INSTALL_CONCURRENCY = '4'  // Instead of 8
```

**Trade-off:**
- Build time: 15 min → 25 min
- Memory usage: 5.2 GB → 3.5 GB
- Fits in t3.medium (4 GB)
- Cost: $0 extra

### Option 3: t3.xlarge (OVERKILL but future-proof)
```
Instance: t3.xlarge
├─ vCPU: 4 cores
├─ RAM: 16 GB
├─ Cost: ~$120/month (+$90/month)
└─ Headroom: 10 GB for future growth

When to use:
✅ Plan to add more services
✅ Want <10 minute builds
✅ Need multiple Jenkins jobs
✅ Budget allows
```

### Option 4: Separate SonarQube Server
```
Jenkins EC2: t3.medium (4 GB)
SonarQube EC2: t3.medium (4 GB)
Total Cost: ~$60/month (+$30/month)

Benefits:
✅ Isolated workloads
✅ SonarQube won't impact builds
✅ Can scale independently
```

## 🎯 Immediate Actions

### If Using t3.medium (Current)

**Update Jenkinsfile to reduce parallelization:**

```groovy
environment {
    // Reduced parallelization for t3.medium (4 GB RAM)
    PARALLEL_BUILD_JOBS = '2'        // Was: 4
    PARALLEL_DEPLOY_JOBS = '2'       // Was: 3
    NPM_INSTALL_CONCURRENCY = '4'    // Was: 8
}
```

**Expected results:**
- Build time: ~25 minutes (still 2.8x faster)
- Memory usage: ~3.5 GB (fits in 4 GB)
- Reduced risk of OOM kills

### Monitoring Commands

```bash
# SSH to Jenkins EC2
ssh -i terraform/jenkins-key.pem ubuntu@<jenkins-ip>

# Monitor memory during build
watch -n 1 free -h

# Monitor Docker resource usage
docker stats

# Check for OOM kills
dmesg | grep -i "out of memory"

# Jenkins logs
tail -f /var/log/jenkins/jenkins.log
```

## 📊 Cost-Benefit Analysis

| Option | Monthly Cost | Build Time | Reliability | Scalability |
|--------|--------------|------------|-------------|-------------|
| **t3.medium + reduced parallel** | $30 | 25 min | 85% | Limited |
| **t3.large** | $60 | 15 min | 99% | Good |
| **t3.xlarge** | $120 | 10 min | 99.9% | Excellent |
| **2x t3.medium** | $60 | 15 min | 95% | Good |

## 🔧 Terraform Update (If Upgrading)

### Upgrade to t3.large

```hcl
# In terraform/variables.tf
variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins server"
  type        = string
  default     = "t3.large"  # Changed from t3.medium
}
```

**Apply changes:**
```bash
cd terraform
terraform plan
terraform apply

# Instance will be recreated
# Downtime: ~5 minutes
```

## ⚡ Performance Expectations

### t3.medium (4 GB) - Reduced Parallel
```
Timeline:
├─ Checkout + Trivy:        2 min
├─ Dependencies (4 parallel): 4 min  
├─ SonarQube:               3 min
├─ Docker Batch 1 (2):      7 min
├─ Docker Batch 2 (2):      7 min
├─ Trivy Scans (4 parallel): 3 min
└─ Deploy:                  1 min
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: ~25 minutes
```

### t3.large (8 GB) - Full Parallel
```
Timeline:
├─ Checkout + Trivy:        1 min
├─ Dependencies (8 parallel): 2 min
├─ SonarQube (parallel):    0 min
├─ Docker Batch 1 (4):      5 min
├─ Docker Batch 2 (3):      5 min
├─ Trivy Scans (8 parallel): 2 min
└─ Deploy:                  1 min
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: ~15 minutes
```

## 🎬 Recommendation

### For Production/Serious Use:
**Upgrade to t3.large ($60/month)**
- Reliable 15-minute builds
- No memory issues
- Professional setup

### For Learning/Testing:
**Keep t3.medium with reduced parallelization**
- Update Jenkinsfile (provided below)
- Save $30/month
- Acceptable 25-minute builds

### For Enterprise/Team:
**Use t3.xlarge or separate instances**
- Multiple concurrent builds
- <10 minute builds
- Future-proof

## 📝 Files to Update

I'll create the reduced-parallelization version for t3.medium compatibility.
