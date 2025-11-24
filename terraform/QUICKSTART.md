# Quick Start Guide - Terraform AWS Deployment

## Step-by-Step Deployment

### Prerequisites Setup

#### A. MongoDB Atlas (Free)
1. Go to https://www.mongodb.com/cloud/atlas/register
2. Create free account and cluster (M0 - Free tier)
3. Create database user:
   - Username: `kahoot`
   - Password: (generate strong password)
4. Network Access → Add IP: `0.0.0.0/0` (allow from anywhere)
5. Get connection string:
   ```
   mongodb+srv://kahoot:<password>@cluster0.xxxxx.mongodb.net/kahoot?retryWrites=true&w=majority
   ```

#### B. Email Setup (Optional, for OTP)
1. Use your Gmail account
2. Enable 2-Factor Authentication
3. Create App Password:
   - Go to: https://myaccount.google.com/apppasswords
   - Create "Kahoot App" password
   - Save the 16-character password

#### C. Install Terraform
```powershell
# Using Chocolatey
choco install terraform

# Verify installation
terraform version
```

### Configure Deployment

```powershell
# Clone repository (if not already)
git clone https://github.com/Thang141104/DevOps-Kahoot-Clone.git
cd DevOps-Kahoot-Clone

# Navigate to terraform directory
cd terraform

# Create configuration file
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
# AWS Credentials (Already provided)
aws_access_key = "AKIA3VT4OHCO6QCERWVC"
aws_secret_key = "PGLwfMZfnIhcmDqCr7BXXE3HtMwhzHBtnPWm5U+K"
aws_region     = "us-east-1"

# MongoDB Atlas (REQUIRED - from Step 1A)
mongodb_uri = "mongodb+srv://kahoot:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/kahoot?retryWrites=true&w=majority"

# Email Configuration (Optional - from Step 1B)
email_user     = "your-email@gmail.com"
email_password = "your-16-char-app-password"

# JWT Secret (Generate random string)
jwt_secret = "my-super-secret-jwt-key-2024-xyz"

# Instance Configuration
instance_type  = "t3.small"    # or "t3.micro" for free tier
use_elastic_ip = true          # Fixed IP address
environment    = "production"

# GitHub Configuration
github_repo   = "https://github.com/Thang141104/DevOps-Kahoot-Clone.git"
github_branch = "main"
```

### Deploy Infrastructure

#### Option A: Automated Script (Recommended)
```powershell
./deploy.ps1
```

#### Option B: Manual Commands
```powershell
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create infrastructure
terraform apply
# Type 'yes' when prompted
```

**Wait 5-10 minutes for deployment...**

### Access Your Application

After deployment completes:

```powershell
# Get all outputs
terraform output
```

You'll see:
- **Frontend URL**: `http://<PUBLIC_IP>:3006` ← Open this in browser
- **API Gateway**: `http://<PUBLIC_IP>:3000`
- **SSH Command**: For server access

**Important**: Wait 2-3 minutes for Docker containers to fully start!

### Verify Deployment

#### Check Application Health
Open in browser:
- Frontend: `http://<PUBLIC_IP>:3006`
- Gateway: `http://<PUBLIC_IP>:3000/health`
- Auth: `http://<PUBLIC_IP>:3001/health`
- Quiz: `http://<PUBLIC_IP>:3002/health`
- Game: `http://<PUBLIC_IP>:3003/health`
- User: `http://<PUBLIC_IP>:3004/health`
- Analytics: `http://<PUBLIC_IP>:3005/health`

#### SSH Access (Optional)
```powershell
# If you configured SSH key
ssh -i kahoot-key.pem ubuntu@<PUBLIC_IP>

# Check Docker status
docker-compose ps
docker-compose logs -f
```

## 🎉 Success!

Your Kahoot Clone is now live on AWS!

## Update Application

```powershell
# SSH to server
ssh -i kahoot-key.pem ubuntu@<PUBLIC_IP>

# Update code
cd /home/ubuntu/app
git pull origin main

# Rebuild containers
docker-compose up -d --build

# Check status
docker-compose ps
```

## Destroy Infrastructure

**WARNING**: This deletes everything!

```powershell
cd terraform

# Option A: Use script
./destroy.ps1

# Option B: Manual
terraform destroy
# Type 'yes' to confirm
```

##  Troubleshooting

### Issue: Services not starting
```powershell
# SSH to server
ssh -i kahoot-key.pem ubuntu@<PUBLIC_IP>

# Check logs
cd /home/ubuntu/app
docker-compose logs

# Restart services
docker-compose restart

# Check individual service
docker-compose logs auth-service
docker-compose logs frontend
```

### Issue: Cannot connect to MongoDB
- Verify connection string in `terraform.tfvars`
- Check MongoDB Atlas network access (whitelist 0.0.0.0/0)
- Test connection string locally

### Issue: OTP emails not sending
- Verify Gmail App Password is correct
- Check auth-service logs: `docker-compose logs auth-service`
- Ensure 2FA is enabled on Gmail

### Issue: Port not accessible
- Check AWS Security Group in EC2 console
- Verify instance is running: `terraform show`
- Wait 2-3 minutes for services to fully start

## Support

### Useful Commands

```powershell
# View infrastructure
terraform show

# Get specific output
terraform output frontend_url
terraform output ssh_connection

# Refresh outputs
terraform refresh
terraform output

# View state
terraform state list

# Format files
terraform fmt
```
