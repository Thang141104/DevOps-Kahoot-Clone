# Terraform Infrastructure for Kahoot Clone

This Terraform configuration deploys the Kahoot Clone application to AWS with a minimal, cost-effective setup.

## Infrastructure Components

- **VPC**: Custom VPC with 1 public subnet
- **Internet Gateway**: For internet connectivity
- **Security Group**: Opens necessary ports (22, 80, 443, 3000-3006)
- **EC2 Instance**: Ubuntu 22.04 (t3.small or t3.micro)
- **Elastic IP** (Optional): For fixed public IP
- **User Data**: Automated setup script that:
  - Installs Docker & Docker Compose
  - Clones your repository
  - Creates environment files
  - Builds and runs all services via Docker Compose

## Prerequisites

### 1. AWS Account Setup
- IAM User created: `Terraform`
- Access Key: `AKIA3VT4OHCO6QCERWVC`
- Secret Key: `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`

### 2. MongoDB Atlas Setup
1. Create a free MongoDB Atlas account: https://www.mongodb.com/cloud/atlas
2. Create a free cluster (M0)
3. Create a database user
4. Whitelist IP: `0.0.0.0/0` (Allow access from anywhere)
5. Get connection string: `mongodb+srv://<username>:<password>@<cluster>.mongodb.net/`

### 3. Email Setup (Optional, for OTP)
1. Use Gmail account
2. Enable 2-Factor Authentication
3. Generate App Password: https://myaccount.google.com/apppasswords
4. Use this app password in configuration

### 4. SSH Key Pair (Optional)
1. Go to AWS EC2 Console → Key Pairs
2. Create a new key pair (e.g., `kahoot-key`)
3. Download the `.pem` file
4. Keep it safe for SSH access

### 5. Install Terraform
```powershell
# Using Chocolatey
choco install terraform

# Or download from: https://www.terraform.io/downloads
```

## Deployment Steps

### Step 1: Configure Variables
```powershell
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
```hcl
# AWS Credentials (Already provided)
aws_access_key = "AKIA3VT4OHCO6QCERWVC"
aws_secret_key = "PGLwfMZfnIhcmDqCr7BXXE3HtMwhzHBtnPWm5U+K"
aws_region     = "us-east-1"

# MongoDB Atlas Connection (REQUIRED - Get from MongoDB Atlas)
mongodb_uri = "mongodb+srv://username:password@cluster.mongodb.net/kahoot?retryWrites=true&w=majority"

# Email for OTP (Optional)
email_user     = "your-email@gmail.com"
email_password = "your-gmail-app-password"

# JWT Secret (Generate a random string)
jwt_secret = "your-super-secret-jwt-key-xyz123"

# EC2 Instance
instance_type = "t3.small"  # Use "t3.micro" for free tier

# SSH Key (Optional - if you created one)
key_name = "kahoot-key"

# Elastic IP
use_elastic_ip = true  # Set false to save costs
```

### Step 2: Initialize Terraform
```powershell
cd terraform
terraform init
```

### Step 3: Review Infrastructure Plan
```powershell
terraform plan
```

This will show you what resources will be created.

### Step 4: Deploy Infrastructure
```powershell
terraform apply
```

Type `yes` when prompted. Deployment takes ~5-10 minutes.

### Step 5: Get Outputs
```powershell
terraform output
```

You'll see:
- **Frontend URL**: `http://<IP>:3006`
- **API Gateway URL**: `http://<IP>:3000`
- **SSH Command**: For server access

## Verify Deployment

### Check Application Status
```powershell
# SSH into the server (if you configured SSH key)
ssh -i kahoot-key.pem ubuntu@<PUBLIC_IP>

# Check Docker containers
docker-compose ps

# Check logs
docker-compose logs -f

# Check specific service logs
docker-compose logs -f frontend
docker-compose logs -f gateway
docker-compose logs -f auth-service
```

### Access Application
1. **Frontend**: http://\<PUBLIC_IP\>:3006
2. **API Gateway**: http://\<PUBLIC_IP\>:3000/health
3. **Individual Services**:
   - Auth: http://\<PUBLIC_IP\>:3001/health
   - Quiz: http://\<PUBLIC_IP\>:3002/health
   - Game: http://\<PUBLIC_IP\>:3003/health
   - User: http://\<PUBLIC_IP\>:3004/health
   - Analytics: http://\<PUBLIC_IP\>:3005/health

## Useful Commands

### Terraform Commands
```powershell
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format configuration files
terraform fmt

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# Get outputs
terraform output

# Destroy infrastructure (WARNING: Deletes everything!)
terraform destroy
```

### Docker Commands (on EC2)
```powershell
# View all containers
docker-compose ps

# View logs
docker-compose logs -f

# Restart all services
docker-compose restart

# Stop all services
docker-compose stop

# Start all services
docker-compose start

# Rebuild and restart
docker-compose up -d --build

# Remove all containers
docker-compose down

# View resource usage
docker stats
```

## Security Considerations

### Important Security Notes

1. **SSH Access**: Currently open to `0.0.0.0/0` (world). In production:
   ```hcl
   # In security-groups.tf, change:
   cidr_blocks = ["0.0.0.0/0"]
   # To your IP:
   cidr_blocks = ["YOUR_IP/32"]
   ```

2. **Secrets Management**: 
   - Never commit `terraform.tfvars` to Git
   - Use AWS Secrets Manager or Parameter Store for production
   - Rotate credentials regularly

3. **Database Access**:
   - MongoDB Atlas: Whitelist specific IPs instead of `0.0.0.0/0`
   - Enable MongoDB authentication
   - Use strong passwords

4. **HTTPS**:
   - Current setup uses HTTP only
   - For production, add SSL/TLS certificate (Let's Encrypt)
   - Use AWS Certificate Manager with Load Balancer

## Troubleshooting

### Issue: Services not starting
```powershell
# SSH into server
ssh -i kahoot-key.pem ubuntu@<PUBLIC_IP>

# Check logs
cd /home/ubuntu/app
docker-compose logs

# Check specific service
docker-compose logs auth-service
```

### Issue: Can't connect to MongoDB
- Verify MongoDB Atlas connection string
- Check if IP is whitelisted in MongoDB Atlas
- Test connection: `mongosh "your-connection-string"`

### Issue: Email/OTP not working
- Verify Gmail App Password is correct
- Check if 2FA is enabled on Gmail account
- Review auth-service logs: `docker-compose logs auth-service`

### Issue: Terraform apply fails
```powershell
# Clean up and retry
terraform destroy
rm -rf .terraform
rm .terraform.lock.hcl
terraform init
terraform apply
```

## Update Deployment

### Update Application Code
```powershell
# SSH into server
ssh -i kahoot-key.pem ubuntu@<PUBLIC_IP>

# Pull latest code
cd /home/ubuntu/app
git pull origin main

# Rebuild and restart
docker-compose up -d --build
```

### Update Infrastructure
```powershell
# Modify Terraform files
# Then apply changes
terraform plan
terraform apply
```

## Cleanup

### Destroy Infrastructure
```powershell
# WARNING: This will delete everything!
terraform destroy
```

Type `yes` when prompted.

This will:
- Terminate EC2 instance
- Delete VPC and subnets
- Remove security groups
- Release Elastic IP
- Delete all AWS resources

**Note**: MongoDB Atlas data will NOT be deleted (managed separately).

cd d:\Phúc\STUDY\DevOps\DevOps-Kahoot-Clone\terraform
terraform apply -auto-approve