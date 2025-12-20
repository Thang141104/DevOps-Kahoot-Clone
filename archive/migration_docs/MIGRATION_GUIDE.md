# Migration Guide - OLD → NEW Infrastructure

## 🎯 Overview

This guide helps you migrate from the old infrastructure (terraform/, ansible/) to the new professional structure (infrastructure/).

## ⚠️ IMPORTANT

**DO NOT delete old files until migration is complete and tested!**

Your current infrastructure is **WORKING** - we'll preserve all critical data.

## 📋 Migration Steps

### Step 1: Analyze Current Structure

```powershell
.\migrate.ps1 -Action analyze
```

This will show:
- ✓ What files exist
- ✓ What needs to be migrated
- ✓ What's safe to cleanup

### Step 2: Run Migration

```powershell
.\migrate.ps1 -Action migrate
```

This will:
1. Create backup directory with timestamp
2. Backup Terraform state
3. Migrate terraform.tfvars to infrastructure/
4. Copy SSH keys
5. Backup old Ansible playbooks

**Files migrated:**
- `terraform/terraform.tfvars` → `infrastructure/terraform/terraform.tfvars`
- `terraform/*.pem` → `infrastructure/terraform/*.pem`
- Terraform state → `backup_YYYYMMDD_HHMMSS/`

### Step 3: Review Migrated Files

Check `infrastructure/terraform/terraform.tfvars`:
```powershell
code infrastructure\terraform\terraform.tfvars
```

**Important:** Update secrets management:
- Use AWS CLI profile instead of hardcoded keys
- Move MongoDB URI, email credentials to Kubernetes secrets
- Store JWT secret in Kubernetes secrets

### Step 4: Option A - Import Existing Resources (Recommended)

If you want to manage existing ECR repositories with new infrastructure:

```powershell
cd infrastructure\terraform
terraform init

# Import existing ECR repositories
terraform import 'module.ecr.aws_ecr_repository.repositories["gateway"]' kahoot-clone-gateway
terraform import 'module.ecr.aws_ecr_repository.repositories["auth"]' kahoot-clone-auth
terraform import 'module.ecr.aws_ecr_repository.repositories["user"]' kahoot-clone-user
terraform import 'module.ecr.aws_ecr_repository.repositories["quiz"]' kahoot-clone-quiz
terraform import 'module.ecr.aws_ecr_repository.repositories["game"]' kahoot-clone-game
terraform import 'module.ecr.aws_ecr_repository.repositories["analytics"]' kahoot-clone-analytics
terraform import 'module.ecr.aws_ecr_repository.repositories["frontend"]' kahoot-clone-frontend

# Verify
terraform plan  # Should show no changes
```

### Step 4: Option B - Fresh Start (Simpler)

Deploy new infrastructure alongside old (will create new ECR repos):

```powershell
.\infrastructure\deploy.ps1 -Action terraform
```

**Note:** This creates new resources, doesn't affect existing ones.

### Step 5: Test New Infrastructure

```powershell
# Deploy everything
.\infrastructure\deploy.ps1 -Action all

# Or step-by-step
.\infrastructure\deploy.ps1 -Action terraform  # Infrastructure
.\infrastructure\deploy.ps1 -Action ansible    # Configuration
```

### Step 6: Update Application Config

Update Jenkinsfile and K8s deployments to use new ECR registry (if needed):

```yaml
# k8s/gateway-deployment.yaml
spec:
  containers:
  - name: gateway
    image: <NEW_ACCOUNT_ID>.dkr.ecr.ap-southeast-1.amazonaws.com/kahoot-clone-gateway:latest
```

### Step 7: Cleanup Old Structure (Optional)

After verifying new infrastructure works:

```powershell
.\migrate.ps1 -Action cleanup
```

This removes:
- `terraform/.terraform/` (temp files)
- `terraform/tfplan` (temp files)
- `ansible/*.retry` (temp files)

**Keeps:**
- `terraform/terraform.tfstate` (for reference)
- `terraform/terraform.tfvars` (backup)
- `Jenkinsfile` (in use)
- `k8s/` (in use)

## 🔍 What Gets Migrated

### ✅ Preserved (Critical)

| Old Location | New Location | Purpose |
|--------------|--------------|---------|
| `terraform/terraform.tfstate` | `backup_*/` | Live AWS resources |
| `terraform/terraform.tfvars` | `infrastructure/terraform/` | Credentials & config |
| `terraform/*.pem` | `infrastructure/terraform/` | SSH keys |
| `ansible/playbooks/*.yml` | `backup_*/` | Custom configurations |

### ✅ Kept in Place (Working)

- `Jenkinsfile` - Already configured for ECR
- `k8s/*.yaml` - Deployments working
- `frontend/`, `gateway/`, `services/` - Application code

### 🗑️ Safe to Delete (After Migration)

- `terraform/.terraform/` - Terraform cache
- `terraform/tfplan` - Plan files
- `ansible/*.retry` - Ansible retry files
- Old documentation duplicates

## 📊 Comparison: OLD vs NEW

### OLD Structure

```
terraform/
├── terraform.tfstate  ← Live resources
├── ecr.tf
├── vpc.tf
├── jenkins-infrastructure.tf
└── k8s-cluster.tf

ansible/
├── playbooks/
│   ├── jenkins-setup.yml
│   └── k8s-setup.yml
└── inventory/
```

**Pros:** Already working, has live resources
**Cons:** Not modular, harder to maintain

### NEW Structure

```
infrastructure/
├── terraform/
│   ├── main.tf
│   ├── modules/
│   │   ├── networking/
│   │   ├── security/
│   │   ├── compute/
│   │   └── ecr/
│   └── terraform.tfvars
└── ansible/
    ├── roles/
    │   ├── common/
    │   ├── docker/
    │   ├── jenkins/
    │   └── kubernetes/
    └── playbooks/site.yml
```

**Pros:** Modular, reusable, professional
**Cons:** Requires migration

## 🛡️ Safety Measures

1. **Automatic Backups**
   - Migration creates timestamped backup directory
   - Original files preserved

2. **Non-Destructive**
   - Migration copies, doesn't delete
   - Cleanup is separate step

3. **Verification**
   - Review migrated files before proceeding
   - Test new infrastructure before cleanup

## ⚠️ Common Issues

### Issue: "Terraform state locked"

```powershell
cd terraform
terraform force-unlock <lock-id>
```

### Issue: "ECR repository already exists"

Use import instead of create:
```powershell
terraform import 'module.ecr.aws_ecr_repository.repositories["gateway"]' kahoot-clone-gateway
```

### Issue: "SSH key not found"

```powershell
# Copy from old location
Copy-Item terraform\*.pem infrastructure\terraform\
```

## 📚 Post-Migration

### Update Documentation

- [ ] Update README.md with new structure
- [ ] Update deployment instructions
- [ ] Document secrets management approach

### Update CI/CD

- [ ] Jenkins credentials for new infrastructure
- [ ] Update Jenkinsfile if needed
- [ ] Update K8s deployment manifests

### Secrets Management

Move to secure storage:
```powershell
# AWS credentials
aws configure --profile kahoot-clone

# Kubernetes secrets
kubectl create secret generic app-secrets \
  --from-literal=MONGODB_URI='...' \
  --from-literal=JWT_SECRET='...' \
  --from-literal=EMAIL_PASSWORD='...'
```

## 🚀 Quick Reference

```powershell
# Analyze
.\migrate.ps1 -Action analyze

# Migrate
.\migrate.ps1 -Action migrate

# Deploy new infrastructure
.\infrastructure\deploy.ps1 -Action all

# Cleanup old files
.\migrate.ps1 -Action cleanup

# Rollback (if needed)
# Just use backup directory - old files preserved
```

## ✅ Success Criteria

Migration is successful when:
- ✓ All credentials migrated
- ✓ SSH keys copied
- ✓ Terraform state backed up
- ✓ New infrastructure deploys
- ✓ Ansible configures servers
- ✓ Jenkins pipeline works
- ✓ K8s deployments pull from ECR

## 💡 Recommendations

**For Development:**
- Use new structure immediately
- Test and iterate

**For Production:**
- Keep old structure running
- Test new structure in parallel
- Migrate when confident

**Hybrid Approach (Best):**
- Keep old for existing resources
- Use new for future additions
- Gradually migrate over time
