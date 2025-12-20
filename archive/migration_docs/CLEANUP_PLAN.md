# 🧹 Project Cleanup Plan

## Current Status

✅ **Analysis Complete**: Both old and new structures exist
✅ **New Structure**: Professional infrastructure ready in `infrastructure/`
✅ **Terraform State**: Found at `terraform/terraform.tfstate` (contains live AWS resources)

## ⚠️ Critical Discovery

**Your old infrastructure IS deployed** - Terraform state contains live AWS resources:
- VPC, Subnets, Internet Gateway
- EC2 instances (Jenkins, K8s Master, K8s Workers)
- ECR repositories (7 repos for microservices)
- Security groups, IAM roles

**DO NOT DELETE** without proper migration!

## 📋 Cleanup Strategy

### Phase 1: Safe Migration (Do Now) ✅

1. **Backup Terraform State**
   ```powershell
   .\migrate.ps1 -Action migrate
   ```
   This will:
   - Create backup directory with timestamp
   - Backup `terraform/terraform.tfstate`
   - Copy credentials to new structure
   - Preserve SSH keys

2. **Update Documentation**
   - ✅ `MIGRATION_GUIDE.md` created
   - ✅ `infrastructure/README.md` updated
   - Update main `README.md` to point to new structure

### Phase 2: Parallel Operation (Recommended)

Keep BOTH structures for now:

**OLD Structure (terraform/, ansible/):**
- ✅ Managing EXISTING AWS resources
- ✅ ECR: 802346121373.dkr.ecr.ap-southeast-1.amazonaws.com
- ✅ Jenkinsfile configured
- ✅ K8s deployments working

**NEW Structure (infrastructure/):**
- ✅ Ready for FUTURE deployments
- ✅ Professional modular design
- ✅ Can create new environments

**Benefits:**
- Zero downtime
- Test new structure without affecting production
- Gradual migration path

### Phase 3: Full Migration (Future)

When you're ready to fully migrate:

#### Option A: Import Resources (Advanced)

Import existing AWS resources into new Terraform:

```powershell
cd infrastructure\terraform
terraform init

# Import VPC
terraform import 'module.networking.aws_vpc.main' <vpc-id>

# Import ECR repositories
terraform import 'module.ecr.aws_ecr_repository.repositories["gateway"]' kahoot-clone-gateway
# ... repeat for all 7 repos
```

**Pros:** Manage everything with new structure
**Cons:** Complex, requires manual imports

#### Option B: Fresh Start (Simpler)

Deploy new infrastructure for new projects:

```powershell
.\infrastructure\deploy.ps1 -Action all
```

**Pros:** Clean, professional setup
**Cons:** Creates duplicate resources (cost)

#### Option C: Coexistence (Recommended)

- OLD: Manages current production (keep as-is)
- NEW: Used for new features/environments
- Gradually decommission old

### Phase 4: Cleanup Old Files (After Full Migration)

Only after you've verified new structure works:

```powershell
.\migrate.ps1 -Action cleanup
```

This removes:
- `terraform/.terraform/` (cache)
- `terraform/tfplan` (temp files)
- `ansible/*.retry` (temp files)

**Still keeps:**
- `terraform/terraform.tfstate` (backup)
- `terraform/terraform.tfvars` (backup)

## 🗂️ What to Keep vs Delete

### 🔒 NEVER DELETE (Critical)

| File | Reason | Location |
|------|--------|----------|
| `terraform/terraform.tfstate` | Live AWS resources | Keep in backup |
| `terraform/terraform.tfvars` | Credentials | Migrate to new |
| `terraform/*.pem` | SSH keys | Copy to new |
| `Jenkinsfile` | Working CI/CD | Keep (in use) |
| `k8s/*.yaml` | Deployments | Keep (in use) |

### ✅ Safe to Delete (After Backup)

| File/Directory | Reason | When |
|----------------|--------|------|
| `terraform/.terraform/` | Terraform cache | After backup |
| `terraform/tfplan` | Plan files | After backup |
| `ansible/*.retry` | Ansible retry | Anytime |
| Old docs duplicates | Consolidated | After review |

### 📝 Keep but Archive

| File | Reason | Action |
|------|--------|--------|
| `terraform/*.tf` | Old infrastructure code | Move to `archive/` |
| `ansible/playbooks/` | Old playbooks | Move to `archive/` |
| Old `deploy.ps1` | Reference | Keep for comparison |

## 🎯 Recommended Approach

### Step 1: Backup Everything (DO NOW)

```powershell
# Run migration to create backups
.\migrate.ps1 -Action migrate

# Verify backup
ls backup_*
```

### Step 2: Update Documentation

```powershell
# Update main README to reference new structure
code README.md
```

Add at top:
```markdown
## 🏗️ Infrastructure

This project uses a **modular infrastructure** approach:
- **New projects**: Use `infrastructure/` (Terraform modules + Ansible roles)
- **Existing resources**: Managed by `terraform/` (legacy)
- **Migration guide**: See [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
```

### Step 3: Test New Structure

```powershell
# Validate new Terraform (dry run)
cd infrastructure\terraform
terraform init
terraform validate
terraform plan
```

### Step 4: Use New Structure for New Work

All future changes go to `infrastructure/`:
```powershell
# Deploy new environment
.\infrastructure\deploy.ps1 -Action all
```

### Step 5: Cleanup Old Files (LATER)

When you're confident:

```powershell
# Clean temp files only
.\migrate.ps1 -Action cleanup

# Archive old structure
mkdir archive
Move-Item terraform archive\terraform-legacy
Move-Item ansible archive\ansible-legacy
```

## 📊 Comparison: Before vs After

### Before Cleanup

```
DevOps-Kahoot-Clone/
├── terraform/           # OLD: 10 files, managing live resources
├── ansible/             # OLD: Legacy playbooks
├── infrastructure/      # NEW: Professional structure
├── Jenkinsfile          # WORKING
├── k8s/                 # WORKING
└── ...
```

**Issues:**
- Confusing dual structure
- Hard to know which to use
- Documentation scattered

### After Cleanup

```
DevOps-Kahoot-Clone/
├── infrastructure/      # ✓ Primary infrastructure
│   ├── terraform/       # ✓ Modular Terraform
│   ├── ansible/         # ✓ Role-based Ansible
│   └── deploy.ps1       # ✓ One-command deployment
├── Jenkinsfile          # ✓ CI/CD pipeline
├── k8s/                 # ✓ Kubernetes deployments
├── archive/             # 📦 Old structure (backup)
│   ├── terraform-legacy/
│   └── ansible-legacy/
└── backup_*/            # 💾 Terraform state backups
```

**Benefits:**
- ✓ Clear structure
- ✓ Professional organization
- ✓ Easy to maintain
- ✓ Backups preserved

## 🚨 Safety Checklist

Before deleting ANY file:

- [ ] Terraform state backed up
- [ ] Credentials migrated to new structure
- [ ] SSH keys copied
- [ ] New infrastructure tested
- [ ] Documentation updated
- [ ] Team informed

## 💡 Quick Commands

```powershell
# Analyze current state
.\migrate.ps1 -Action analyze

# Create backups and migrate
.\migrate.ps1 -Action migrate

# Test new infrastructure
.\infrastructure\deploy.ps1 -Action terraform -DryRun

# Clean temp files only
.\migrate.ps1 -Action cleanup

# Archive old structure (manual)
mkdir archive
Move-Item terraform archive\terraform-legacy
Move-Item ansible archive\ansible-legacy
```

## 📞 Need Help?

If migration fails:
1. **Terraform state is safe** - in `backup_*/`
2. **Original files preserved** - migration copies, doesn't delete
3. **Rollback**: Use backup directory

## ✅ Success Criteria

Cleanup successful when:
- ✓ Terraform state backed up
- ✓ Credentials migrated
- ✓ New structure validated
- ✓ Documentation updated
- ✓ Team can deploy using `infrastructure/`
- ✓ Old structure archived (not deleted)

## 🎉 Final State

After cleanup:
- **Primary**: `infrastructure/` for all new work
- **Archive**: Old files safely preserved
- **Working**: Jenkinsfile, K8s deployments untouched
- **Clean**: No duplicate/confusing files
