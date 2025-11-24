# 🔐 SECURITY GUIDE - SENSITIVE FILES

## ⚠️ IMPORTANT: Files to NEVER commit to git

### 1. SSH Private Keys
```
terraform/kahoot-key.pem
terraform/*.pem
*.key
```

### 2. Terraform State & Variables
```
terraform/terraform.tfstate
terraform/terraform.tfstate.backup
terraform/terraform.tfvars
```

**Contains:**
- AWS Access Keys
- AWS Secret Keys
- MongoDB passwords
- Email passwords
- JWT secrets

### 3. Kubernetes Secrets
```
k8s/secrets.yaml
```

**Contains:**
- MongoDB connection string with password
- JWT secret keys
- Email credentials
- Session secrets

### 4. Environment Files
```
.env
*/.env
**/.env
```

**Contains:**
- Database credentials
- API keys
- Service secrets

---

## ✅ Safe Files to Commit

### Example Files (Template only)
```
.env.example
terraform/terraform.tfvars.example
k8s/secrets.yaml.example
```

These files contain placeholders and instructions, not real credentials.

---

## 🛡️ What to Do If You Accidentally Committed Secrets

### 1. Immediately Rotate All Credentials
```bash
# Change AWS Keys in AWS Console
# Change MongoDB password in MongoDB Atlas
# Generate new JWT secrets
# Change email app password
```

### 2. Remove from Git History
```bash
# Install BFG Repo Cleaner
git clone --mirror https://github.com/YOUR_REPO.git
bfg --delete-files terraform.tfvars
bfg --delete-files secrets.yaml
cd YOUR_REPO.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force
```

### 3. Force Push (DANGEROUS - coordinate with team)
```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch terraform/terraform.tfvars" \
  --prune-empty --tag-name-filter cat -- --all

git push --force --all
```

---

## 📋 Security Checklist

- [ ] `.gitignore` updated with all sensitive patterns
- [ ] `terraform/terraform.tfvars` never committed
- [ ] `k8s/secrets.yaml` never committed
- [ ] `*.pem` files never committed
- [ ] `.env` files never committed
- [ ] Example files created (`.example` suffix)
- [ ] AWS credentials rotated regularly
- [ ] MongoDB password uses strong random string
- [ ] JWT secret is cryptographically random
- [ ] Email app password (not regular password) used

---

## 🔑 How to Generate Secure Secrets

### JWT Secret (Node.js)
```javascript
require('crypto').randomBytes(64).toString('hex')
```

### JWT Secret (PowerShell)
```powershell
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})
```

### Session Secret
```bash
openssl rand -base64 32
```

---

## 📚 Resources

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [GitHub Security Guide](https://docs.github.com/en/code-security)
- [MongoDB Atlas Security](https://docs.atlas.mongodb.com/security/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
