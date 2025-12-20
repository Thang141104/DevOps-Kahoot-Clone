# SonarQube Integration Guide

## Overview
SonarQube is integrated into the Jenkins pipeline to perform static code analysis focusing on **CRITICAL** issues only.

## Architecture

```
Jenkins Pipeline → SonarQube Server → Quality Gate → Continue/Fail Build
```

## SonarQube Configuration

### 1. Deploy SonarQube to K8s
```bash
kubectl apply -f k8s/sonarqube-deployment.yaml
```

### 2. Access SonarQube UI
```bash
# Get NodePort
kubectl get svc -n sonarqube sonarqube

# Access via browser
http://<k8s-node-ip>:30900
```

**Default credentials:**
- Username: `admin`
- Password: `admin` (change after first login)

### 3. Generate Authentication Token
1. Login to SonarQube
2. Go to: **My Account** → **Security** → **Generate Tokens**
3. Name: `jenkins-pipeline`
4. Type: `User Token`
5. Copy the generated token

### 4. Add Token to Jenkins
```bash
# In Jenkins UI
Manage Jenkins → Credentials → System → Global credentials → Add Credentials

Kind: Secret text
Secret: <paste-your-sonarqube-token>
ID: sonarqube-token
Description: SonarQube Authentication Token
```

## Pipeline Configuration

### Severity Levels
The pipeline is configured to focus on **CRITICAL** issues only:

```groovy
-Dsonar.severity=CRITICAL
```

### Quality Gate Settings
- Wait for quality gate: `true`
- Timeout: `300 seconds` (5 minutes)
- Action on failure: Report but don't fail build (for now)

### Exclusions
The following are excluded from scans:
- `**/node_modules/**` - Dependencies
- `**/build/**` - Build artifacts
- `**/dist/**` - Distribution files
- `**/*.test.js` - Test files
- `**/*.spec.js` - Spec files

## Custom Quality Gate (Optional)

To create a custom quality gate focusing on critical issues:

1. **In SonarQube UI:**
   - Go to: **Quality Gates** → **Create**
   - Name: `Critical Only`
   
2. **Add Conditions:**
   ```
   Blocker Issues > 0 → FAIL
   Critical Issues > 0 → FAIL
   Security Hotspots Reviewed < 100% → WARN
   ```

3. **Set as Default:**
   - Select the quality gate
   - Click **Set as Default**

## Project Configuration

The `sonar-project.properties` file should contain:

```properties
sonar.projectKey=kahoot-clone
sonar.projectName=Kahoot Clone
sonar.projectVersion=1.0

# Source paths
sonar.sources=.
sonar.exclusions=**/node_modules/**,**/build/**,**/dist/**,**/*.test.js,**/*.spec.js

# JavaScript/TypeScript
sonar.javascript.lcov.reportPaths=coverage/lcov.info

# Quality Gate
sonar.qualitygate.wait=true

# Issue severity filter
sonar.severity=CRITICAL
```

## Trivy Integration

### Scan Types

#### 1. Repository Scan (Before Build)
Scans filesystem for vulnerabilities in dependencies:
```bash
trivy fs --severity CRITICAL,HIGH \
  --skip-dirs node_modules \
  --format table .
```

#### 2. Image Scan (Before Deploy)
Scans Docker images for vulnerabilities:
```bash
trivy image --severity CRITICAL,HIGH \
  --format table \
  <image-name>:<tag>
```

### Severity Levels
- **CRITICAL**: Must fix immediately
- **HIGH**: Fix in next release
- **MEDIUM**: Informational (skipped)
- **LOW**: Informational (skipped)

### Exit Codes
```groovy
TRIVY_EXIT_CODE = '0'  // Don't fail build, just report
```

To fail on vulnerabilities, set:
```groovy
TRIVY_EXIT_CODE = '1'  // Fail if vulnerabilities found
```

## Parallelization Strategy

The pipeline uses parallel execution at multiple stages:

### 1. Initialization
```
┌─ Checkout Code
└─ Trivy Repository Scan
```

### 2. Dependencies & Analysis
```
┌─ Install Dependencies (8 services)
└─ SonarQube Scan
```

### 3. Docker Builds
```
Batch 1: ┌─ Gateway
         ├─ Auth
         ├─ User
         └─ Quiz

Batch 2: ┌─ Game
         ├─ Analytics
         └─ Frontend
```

### 4. Security Scans
```
┌─ Trivy: Gateway
├─ Trivy: Auth
├─ Trivy: User
├─ Trivy: Quiz
├─ Trivy: Game
├─ Trivy: Analytics
├─ Trivy: Frontend
└─ ECR Image Scan
```

## Performance Optimizations

### NPM Install
```groovy
NPM_INSTALL_CONCURRENCY = '8'  // 8 parallel downloads
npm ci --prefer-offline --no-audit --maxsockets=8
```

### Docker BuildKit
```groovy
DOCKER_BUILDKIT = '1'
--cache-from <image>:latest
--cache-to type=inline
```

### Parallel Stages
- **4 parallel Docker builds** (Batch 1)
- **3 parallel Docker builds** (Batch 2)
- **8 parallel Trivy scans**
- **8 parallel npm installs**

## Expected Timeline

| Stage | Sequential | Parallel | Speedup |
|-------|-----------|----------|---------|
| Initialization | 2 min | 1 min | 2x |
| Dependencies | 16 min | 2 min | 8x |
| SonarQube | 3 min | 0 min* | Runs in parallel |
| Docker Builds | 35 min | 10 min | 3.5x |
| Trivy Scans | 14 min | 2 min | 7x |
| Total | ~70 min | ~15 min | **4.7x faster** |

*SonarQube runs in parallel with dependency installation

## Troubleshooting

### SonarQube Connection Issues
```bash
# Check if SonarQube is running
kubectl get pods -n sonarqube

# Check logs
kubectl logs -n sonarqube deployment/sonarqube

# Test connection from Jenkins
curl http://sonarqube.sonarqube.svc.cluster.local:9000/api/system/status
```

### Trivy Installation Issues
```bash
# Manual install on Jenkins node
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list
apt-get update && apt-get install -y trivy
```

### Quality Gate Timeout
If SonarQube analysis times out:
```groovy
-Dsonar.qualitygate.timeout=600  // Increase to 10 minutes
```

## Security Best Practices

1. **Token Security:**
   - Never commit SonarQube tokens to Git
   - Use Jenkins credentials store
   - Rotate tokens every 90 days

2. **Vulnerability Management:**
   - Fix CRITICAL issues immediately
   - Address HIGH issues within 7 days
   - Review MEDIUM issues monthly

3. **Quality Gates:**
   - Block deployment if CRITICAL issues found
   - Require security hotspot review
   - Maintain 80%+ code coverage (optional)

## Reports & Artifacts

The pipeline archives the following:
- `trivy-repo-scan.json` - Repository vulnerability report
- `security-report.txt` - Summary of all security findings
- SonarQube dashboard - Available at `${SONARQUBE_URL}`

## Next Steps

1. Deploy SonarQube: `kubectl apply -f k8s/sonarqube-deployment.yaml`
2. Configure Jenkins credentials with SonarQube token
3. Run pipeline: Jenkins will automatically scan and report
4. Review reports in SonarQube UI and Jenkins artifacts
5. Configure custom quality gates based on your requirements
