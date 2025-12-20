# Jenkins Pipeline Optimization Guide

## Performance Improvements

### 🚀 Parallelization Strategy

#### Before (Sequential)
```
Total time: ~70 minutes
├─ Checkout: 2 min
├─ Dependencies: 16 min (8 services × 2 min)
├─ SonarQube: 3 min
├─ Docker Builds: 35 min (7 images × 5 min)
├─ Trivy Scans: 14 min (7 images × 2 min)
└─ Deploy: 5 min
```

#### After (Parallel)
```
Total time: ~15 minutes (4.7x faster)
├─ Checkout + Trivy Repo Scan: 1 min (parallel)
├─ Dependencies + SonarQube: 2 min (parallel)
├─ Docker Builds Batch 1: 5 min (4 parallel)
├─ Docker Builds Batch 2: 5 min (3 parallel)
├─ Trivy Image Scans: 2 min (8 parallel)
└─ Deploy: 1 min
```

### ⚡ Optimization Techniques

#### 1. NPM Install Concurrency
```groovy
NPM_INSTALL_CONCURRENCY = '8'
npm ci --prefer-offline --no-audit --maxsockets=8
```
- **8 parallel downloads** per service
- **Offline cache** for repeated packages
- **Skip audit** during build (run separately)

#### 2. Docker BuildKit Cache
```groovy
DOCKER_BUILDKIT = '1'
docker buildx build \
  --cache-from ${ECR_REGISTRY}/image:latest \
  --cache-to type=inline \
  --build-arg BUILDKIT_INLINE_CACHE=1
```
- **Layer caching** from ECR
- **Inline cache** for faster rebuilds
- **~5-10x faster** for unchanged layers

#### 3. Parallel Build Batches
```
Batch 1 (4 images):
┌─ Gateway (lightweight)
├─ Auth (medium)
├─ User (medium)
└─ Quiz (heavy)

Batch 2 (3 images):
┌─ Game (heavy)
├─ Analytics (light)
└─ Frontend (heavy)
```

**Why 2 batches?**
- Prevent Jenkins from running out of resources
- Balance heavy and light builds
- Faster overall completion

#### 4. Parallel Security Scans
```
8 parallel Trivy scans:
┌─ Gateway
├─ Auth
├─ User
├─ Quiz
├─ Game
├─ Analytics
├─ Frontend
└─ ECR Native Scan
```

## SonarQube Configuration

### Focus on Critical Issues Only
```properties
sonar.severity=CRITICAL
sonar.qualitygate.wait=true
sonar.qualitygate.timeout=300
```

### Exclusions
- `**/node_modules/**` - Dependencies
- `**/*.test.js` - Test files
- `**/*.spec.js` - Spec files
- `**/build/**` - Build artifacts
- `**/coverage/**` - Coverage reports

### Skip Non-Critical Issues
```groovy
-Dsonar.severity=CRITICAL
```
- Only report **BLOCKER** and **CRITICAL** issues
- Skip **MAJOR**, **MINOR**, **INFO**
- Faster scan execution
- Focus on security vulnerabilities

## Trivy Configuration

### Two-Stage Scanning

#### Stage 1: Repository Scan (Before Build)
```bash
trivy fs --severity CRITICAL,HIGH \
  --skip-dirs node_modules \
  --format json \
  --output trivy-repo-scan.json \
  .
```
**Purpose:** Catch dependency vulnerabilities early

#### Stage 2: Image Scan (Before Deploy)
```bash
trivy image --severity CRITICAL,HIGH \
  --exit-code 0 \
  --format table \
  ${ECR_REGISTRY}/image:${BUILD_VERSION}
```
**Purpose:** Verify final images are secure

### Severity Filtering
```groovy
TRIVY_SEVERITY = 'CRITICAL,HIGH'
TRIVY_EXIT_CODE = '0'  // Report only, don't fail
```

**To fail on vulnerabilities:**
```groovy
TRIVY_EXIT_CODE = '1'  // Fail if CRITICAL/HIGH found
```

## Resource Requirements

### Jenkins Node Requirements
```yaml
CPU: 8+ cores
Memory: 16+ GB
Disk: 100+ GB (for Docker images)
Network: 1+ Gbps (for ECR push/pull)
```

### Parallel Execution Limits
```groovy
PARALLEL_BUILD_JOBS = '4'    # Max parallel Docker builds
PARALLEL_DEPLOY_JOBS = '3'   # Max parallel deployments
NPM_INSTALL_CONCURRENCY = '8' # Max NPM downloads
```

**Adjust based on your Jenkins node:**
- **8 cores**: Keep defaults
- **4 cores**: Reduce to `PARALLEL_BUILD_JOBS = '2'`
- **16+ cores**: Increase to `PARALLEL_BUILD_JOBS = '6'`

## Expected Timeline Breakdown

| Stage | Time | Parallelization | Notes |
|-------|------|-----------------|-------|
| **Initialization** | 1 min | ✅ Checkout + Trivy Repo | Runs together |
| **ECR Login** | 10 sec | ❌ Sequential | Quick, no need to parallelize |
| **Dependencies** | 2 min | ✅ 8 services + SonarQube | All npm installs run together |
| **SonarQube Scan** | 0 min* | ✅ During dependency install | Runs in parallel |
| **Docker Batch 1** | 5 min | ✅ 4 images | Gateway, Auth, User, Quiz |
| **Docker Batch 2** | 5 min | ✅ 3 images | Game, Analytics, Frontend |
| **Trivy Scans** | 2 min | ✅ 8 parallel | All images + ECR scan |
| **Pre-Deploy** | 30 sec | ✅ Reports + K8s check | Generate security report |
| **Deploy** | 1 min | ❌ Rolling update | Kubernetes rollout |
| **Total** | **~15 min** | - | **4.7x faster than sequential** |

*SonarQube runs in background during dependency installation

## Monitoring & Observability

### Jenkins Blue Ocean
```
Jenkins → Open Blue Ocean → kahoot-clone
```
- Visualize parallel execution
- See stage durations
- Identify bottlenecks

### Timing Analysis
```groovy
timestamps()  // Add timestamps to console output
```

### Resource Monitoring
```bash
# On Jenkins node
top -b -n 1 | grep docker
docker stats --no-stream
```

## Troubleshooting

### Parallel Builds Failing
```groovy
parallelsAlwaysFailFast()  // Stop all if one fails
```
- Check Jenkins node resources
- Reduce `PARALLEL_BUILD_JOBS`
- Check Docker daemon limits

### NPM Install Timeouts
```bash
npm config set fetch-timeout 300000  # 5 minutes
npm config set fetch-retries 5
```

### SonarQube Timeout
```groovy
-Dsonar.qualitygate.timeout=600  # Increase to 10 minutes
```

### Trivy Download Issues
```bash
# Pre-install Trivy on Jenkins node
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list
apt-get update && apt-get install -y trivy
```

## Best Practices

### 1. Cache Everything
- ✅ Docker layer cache (BuildKit)
- ✅ NPM cache (--prefer-offline)
- ✅ Trivy vulnerability DB
- ✅ SonarQube scanner

### 2. Fail Fast
```groovy
parallelsAlwaysFailFast()
```
- Stop all parallel jobs if one fails
- Save time and resources
- Early feedback on errors

### 3. Resource Limits
```groovy
timeout(time: 1, unit: 'HOURS')  // Kill if stuck
```

### 4. Cleanup
```groovy
post {
    always {
        sh 'docker system prune -f --volumes'
    }
}
```
- Clean up old images
- Free disk space
- Prevent disk full errors

## Advanced Optimizations

### Docker Layer Caching Strategy
```dockerfile
# Dockerfile best practices
# 1. Cache dependencies first
COPY package*.json ./
RUN npm ci

# 2. Copy code last (changes frequently)
COPY . .
```

### ECR Lifecycle Policies
```bash
# Keep only 10 latest images
aws ecr put-lifecycle-policy \
  --repository-name kahoot-clone-gateway \
  --lifecycle-policy-text '{
    "rules": [{
      "rulePriority": 1,
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": { "type": "expire" }
    }]
  }'
```

### Jenkins Pipeline Caching
```groovy
// Use shared libraries for common functions
@Library('shared-pipeline-lib') _

// Cache node_modules between builds
dir('/var/jenkins_home/npm-cache') {
    sh 'npm config set cache $(pwd)'
}
```

## Metrics & KPIs

### Build Performance
- **Build Time**: Target < 15 minutes
- **Cache Hit Rate**: Target > 80%
- **Parallel Efficiency**: Target > 4x speedup

### Security
- **Critical Issues**: Target = 0
- **High Issues**: Target < 5
- **Scan Coverage**: Target = 100%

### Quality
- **SonarQube Quality Gate**: Must pass
- **Code Coverage**: Target > 70% (optional)
- **Duplicate Code**: Target < 3%
