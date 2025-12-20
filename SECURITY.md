# 🔒 Security Guide

## Files NEVER commit to Git

### ❌ Critical - Contains Real Credentials
```
*.tfvars                    # Terraform variables with secrets
*.pem, *.key                # SSH private keys
.env                        # Environment variables
k8s/secrets.yaml            # Kubernetes secrets with real values
ecr-config.json             # ECR config with AWS account ID
.deployment-info.json       # Infrastructure IPs and URLs
terraform.tfstate           # Contains all resource info
```

### ✅ Safe to Commit - Example Templates
```
terraform.tfvars.example    # Template without real values
.env.example                # Template without real values
k8s/secrets.yaml.example    # Template without real values
ecr-config.json.example     # Template without real values
```

---

## 🔐 How to Handle Secrets

### 1. Development (Local)
```bash
# Use .env files (git ignored)
cp .env.example .env
# Edit .env with real values
```

### 2. Production (Kubernetes)
```bash
# Create secrets from files (NOT committed to git)
kubectl create secret generic app-secrets \
  --from-literal=MONGODB_URI='mongodb://...' \
  --from-literal=JWT_SECRET='your-secret' \
  --from-literal=EMAIL_PASSWORD='your-password' \
  -n kahoot-clone
```

### 3. AWS Credentials
```bash
# Use IAM roles (no credentials needed)
# Jenkins EC2 → IAM role → ECR access
# K8s nodes → IAM role → ECR pull

# Or use AWS Secrets Manager
aws secretsmanager create-secret \
  --name kahoot-clone/mongodb-uri \
  --secret-string 'mongodb://...'
```

---

## 📋 Pre-Commit Checklist

Before `git commit`:

```powershell
# Run security audit
.\security-audit.ps1

# Check what will be committed
git status

# If you see these files, DO NOT COMMIT:
# - *.tfvars
# - *.pem, *.key
# - .env
# - ecr-config.json
# - secrets.yaml

# Remove from staging
git reset HEAD <sensitive-file>

# Add to .gitignore if needed
echo "ecr-config.json" >> .gitignore
```

---

## 🚨 If You Accidentally Committed Secrets

### Option 1: Hasn't pushed yet
```bash
# Remove from last commit
git reset --soft HEAD~1
git restore --staged <sensitive-file>

# Or amend last commit
git rm --cached <sensitive-file>
git commit --amend --no-edit
```

### Option 2: Already pushed to GitHub
```bash
# ⚠️  CRITICAL: Rotate all exposed secrets immediately!
# 1. Change passwords, regenerate keys
# 2. Use BFG Repo Cleaner to remove from history
git clone --mirror https://github.com/user/repo.git
java -jar bfg.jar --delete-files secrets.yaml repo.git
cd repo.git
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push --force

# 3. Or delete and recreate repository (if small)
```

---

## ✅ Current .gitignore Protection

Your project is protected from committing:

```gitignore
# Terraform
terraform/*.tfvars
terraform/*.tfstate
terraform/*.pem
tfplan

# Environment
.env
**/.env

# Kubernetes
k8s/secrets.yaml
k8s/*-secrets.yaml

# Infrastructure
ecr-config.json
.deployment-info.json

# SSH Keys
*.pem
*.key
*.ppk
```

---

## 🔍 Security Audit Tool

Always run before commit:

```powershell
# Check for sensitive data
.\security-audit.ps1

# Expected output:
# ✅ No sensitive data detected in staged files
#    Safe to commit!
```

---

## 📝 Best Practices

1. ✅ **Use Templates**
   - Commit `.example` files
   - Never commit files with real values

2. ✅ **Use Secrets Management**
   - K8s secrets for production
   - AWS Secrets Manager / Parameter Store
   - Vault for enterprise

3. ✅ **Use IAM Roles**
   - No credentials in code
   - EC2 instances get permissions via IAM

4. ✅ **Regular Audits**
   - Run `security-audit.ps1` before commits
   - Use GitHub secret scanning
   - Enable pre-commit hooks

5. ✅ **Rotate Secrets**
   - Rotate exposed secrets immediately
   - Change passwords regularly
   - Use temporary credentials when possible

---

## 🔗 Resources

- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [git-secrets Tool](https://github.com/awslabs/git-secrets)
