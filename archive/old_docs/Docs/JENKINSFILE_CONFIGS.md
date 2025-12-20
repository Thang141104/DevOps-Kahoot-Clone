# Jenkinsfile Configuration Guide

## Instance Type Configurations

### t3.medium (4 GB RAM) - DEFAULT
```groovy
environment {
    PARALLEL_BUILD_JOBS = '2'
    PARALLEL_DEPLOY_JOBS = '2'
    NPM_INSTALL_CONCURRENCY = '4'
}
```
**Performance:**
- Build time: ~25 minutes
- Memory safe: ✅ Fits in 4 GB
- Reliability: 85% (some slow builds)

---

### t3.large (8 GB RAM) - RECOMMENDED
```groovy
environment {
    PARALLEL_BUILD_JOBS = '4'
    PARALLEL_DEPLOY_JOBS = '3'
    NPM_INSTALL_CONCURRENCY = '8'
}
```
**Performance:**
- Build time: ~15 minutes
- Memory safe: ✅ 2.8 GB headroom
- Reliability: 99%

---

### t3.xlarge (16 GB RAM) - ENTERPRISE
```groovy
environment {
    PARALLEL_BUILD_JOBS = '6'
    PARALLEL_DEPLOY_JOBS = '4'
    NPM_INSTALL_CONCURRENCY = '12'
}
```
**Performance:**
- Build time: ~10 minutes
- Memory safe: ✅ 10 GB headroom
- Reliability: 99.9%

## Quick Switch Instructions

### Currently Using: t3.medium

**To upgrade to t3.large:**

1. **Update Terraform:**
```bash
cd terraform

# Edit variables.tf or terraform.tfvars
# Change: jenkins_instance_type = "t3.large"

terraform plan
terraform apply
```

2. **Update Jenkinsfile:**
```groovy
PARALLEL_BUILD_JOBS = '4'        # Was: 2
NPM_INSTALL_CONCURRENCY = '8'    # Was: 4
```

3. **Verify:**
```bash
# SSH to Jenkins
ssh -i terraform/jenkins-key.pem ubuntu@<jenkins-ip>

# Check memory
free -h
# Should show: ~8 GB total

# Monitor first build
watch -n 1 free -h
```

**Cost Impact:** +$30/month ($60 total)

## Monitoring

### During Build
```bash
# Memory usage
watch -n 1 free -h

# Docker stats
docker stats

# Check for OOM
dmesg | grep -i "out of memory"
```

### Warning Signs
- **Swap usage > 1 GB**: Upgrade needed
- **Available memory < 200 MB**: Reduce parallelization
- **Build time > 30 min**: Check for thrashing

## Performance Expectations

| Instance | Parallel Jobs | Build Time | Monthly Cost |
|----------|---------------|------------|--------------|
| t3.medium | 2 | 25 min | $30 |
| t3.large | 4 | 15 min | $60 |
| t3.xlarge | 6 | 10 min | $120 |
| t3.2xlarge | 8 | 7 min | $240 |
