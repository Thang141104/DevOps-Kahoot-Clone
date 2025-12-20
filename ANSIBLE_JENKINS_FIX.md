# Ansible Playbooks for Jenkins Fixes

## Overview
These Ansible playbooks fix the Jenkins pipeline issues:
1. **Java version mismatch** - SonarQube Scanner requires Java 17+
2. **Resource constraints** - npm builds timeout on t3.medium instance

## Playbooks

### 1. fix-jenkins-java.yml
**Purpose**: Upgrade Jenkins from Java 11 to Java 17

**What it does**:
- Removes OpenJDK 11
- Installs OpenJDK 17
- Reinstalls SonarQube Scanner
- Restarts Jenkins service
- Verifies everything works

**Run with**:
```bash
cd infrastructure/ansible
ansible-playbook playbooks/fix-jenkins-java.yml -i inventory/hosts
```

**Expected output**:
```
✅ Jenkins Java upgrade complete!
- Java 17 installed and verified
- SonarQube Scanner installed and working
- Jenkins service restarted
- Ready for SonarQube analysis in pipeline
```

---

### 2. optimize-jenkins.yml
**Purpose**: Optimize Jenkins for resource-constrained t3.medium instance

**What it does**:
- Configures JVM memory: 2GB max, 1GB min
- Enables G1GC garbage collector
- Sets disk space threshold to 1GB
- Optimizes file descriptors (65536)
- Reduces VM swappiness to 10
- Configures npm maxsockets to 2
- Schedules daily workspace cleanup

**Run with**:
```bash
cd infrastructure/ansible
ansible-playbook playbooks/optimize-jenkins.yml -i inventory/hosts
```

**Expected output**:
```
✅ Jenkins optimization complete!
- JVM memory set to: Xmx2g (max) Xms1g (min)
- G1GC garbage collector enabled
- Disk space threshold: 1GB
- VM swappiness: 10
- File descriptors: 65536
- Workspace cleanup scheduled daily
- npm maxsockets: 2
```

---

## Complete Fix Process

Run both playbooks in order:

```bash
cd infrastructure/ansible

# 1. Fix Java version
ansible-playbook playbooks/fix-jenkins-java.yml -i inventory/hosts

# 2. Optimize Jenkins resources
ansible-playbook playbooks/optimize-jenkins.yml -i inventory/hosts
```

## What Fixes Pipeline Failures

### Build #5 Failures:

1. **SonarQube Java error** ✅ FIXED
   ```
   UnsupportedClassVersionError: class file version 61.0 (Java 17+)
   this version recognizes class file versions up to 55.0 (Java 11)
   ```
   → **Solution**: Upgrade to Java 17 with fix-jenkins-java.yml

2. **npm install timeouts** ✅ FIXED
   ```
   npm ci SIGTERM (8 parallel jobs with 4GB RAM = resource exhaustion)
   ```
   → **Solution**: Optimize JVM memory and npm settings with optimize-jenkins.yml

3. **Groovy string interpolation warning** ✅ FIXED
   ```
   Warning: A secret was passed to "sh" using Groovy String interpolation
   ```
   → The Jenkinsfile already wraps SONAR_TOKEN in withCredentials() block

## Verification

After running both playbooks, verify the fixes:

```bash
# SSH to Jenkins
ssh -i infrastructure/terraform/keys/kahoot-clone-key.pem ubuntu@44.201.44.17

# Check Java version
java -version

# Check SonarQube Scanner
sonar-scanner --version

# Check Jenkins memory settings
grep JAVA_ARGS /etc/default/jenkins
```

Expected output:
```
java version "17.0.x" ...
SonarQube Scanner 4.8.0.2856 ...
JAVA_ARGS="-Xmx2g -Xms1g -XX:+UseG1GC ..."
```

## Next Steps

1. Run both Ansible playbooks
2. Verify Java 17 and SonarQube Scanner installation
3. Trigger Build #6 via GitHub webhook
4. Monitor build progress in Jenkins UI
5. Verify no timeout errors in npm install stage
6. Confirm SonarQube analysis runs successfully

## Rollback (if needed)

If Java 17 causes issues, rollback to Java 11:
```bash
ansible-playbook playbooks/fix-jenkins-java.yml -i inventory/hosts -e "java_version=11"
```

---

**Created**: 2025-12-21
**Status**: Ready to apply
