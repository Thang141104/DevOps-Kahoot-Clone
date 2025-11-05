# Deploy script for Terraform
# This script helps you deploy the infrastructure step by step

Write-Host "=== Kahoot Clone - Terraform Deployment Script ===" -ForegroundColor Cyan
Write-Host ""

# Check if Terraform is installed
try {
    $terraformVersion = terraform version
    Write-Host "Terraform is installed" -ForegroundColor Green
    Write-Host $terraformVersion[0] -ForegroundColor Gray
} catch {
    Write-Host "Terraform is not installed!" -ForegroundColor Red
    Write-Host "Please install Terraform from: https://www.terraform.io/downloads" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Check if terraform.tfvars exists
if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "terraform.tfvars not found!" -ForegroundColor Yellow
    Write-Host "Creating from example file..." -ForegroundColor Gray
    Copy-Item "terraform.tfvars.example" "terraform.tfvars"
    Write-Host ""
    Write-Host "Created terraform.tfvars" -ForegroundColor Green
    Write-Host "IMPORTANT: Please edit terraform.tfvars with your values before continuing!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Required configurations:" -ForegroundColor Cyan
    Write-Host "  1. MongoDB Atlas connection string (mongodb_uri)" -ForegroundColor White
    Write-Host "  2. Email credentials for OTP (email_user, email_password)" -ForegroundColor White
    Write-Host "  3. JWT secret (jwt_secret)" -ForegroundColor White
    Write-Host "  4. AWS region (aws_region)" -ForegroundColor White
    Write-Host "  5. Instance type (instance_type)" -ForegroundColor White
    Write-Host ""
    
    $continue = Read-Host "Have you configured terraform.tfvars? (yes/no)"
    if ($continue -ne "yes") {
        Write-Host "Please configure terraform.tfvars first, then run this script again." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "=== Step 1: Initialize Terraform ===" -ForegroundColor Cyan
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform init failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Terraform initialized successfully" -ForegroundColor Green
Write-Host ""

Write-Host "=== Step 2: Validate Configuration ===" -ForegroundColor Cyan
terraform validate

if ($LASTEXITCODE -ne 0) {
    Write-Host "Configuration validation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Configuration is valid" -ForegroundColor Green
Write-Host ""

Write-Host "=== Step 3: Plan Infrastructure ===" -ForegroundColor Cyan
terraform plan -out=tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform plan failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Plan created successfully" -ForegroundColor Green
Write-Host ""

Write-Host "=== Review the plan above ===" -ForegroundColor Yellow
Write-Host "This will create:" -ForegroundColor Cyan
Write-Host "  - 1 VPC with 1 public subnet" -ForegroundColor White
Write-Host "  - 1 Internet Gateway" -ForegroundColor White
Write-Host "  - 1 Security Group" -ForegroundColor White
Write-Host "  - 1 EC2 Instance (Ubuntu 22.04)" -ForegroundColor White
Write-Host "  - 1 Elastic IP (if enabled)" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Do you want to apply this plan? (yes/no)"

if ($confirm -eq "yes") {
    Write-Host ""
    Write-Host "=== Step 4: Apply Infrastructure ===" -ForegroundColor Cyan
    Write-Host "This will take 5-10 minutes..." -ForegroundColor Yellow
    Write-Host ""
    
    terraform apply tfplan
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform apply failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "=== Deployment Complete! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "=== Step 5: Get Outputs ===" -ForegroundColor Cyan
    terraform output
    
    Write-Host ""
    Write-Host "=== Important Notes ===" -ForegroundColor Yellow
    Write-Host "1. Wait 2-3 minutes for services to fully start" -ForegroundColor White
    Write-Host "2. Access your application at the Frontend URL shown above" -ForegroundColor White
    Write-Host "3. Check health endpoints to verify services are running" -ForegroundColor White
    Write-Host ""
    Write-Host "To SSH into the server:" -ForegroundColor Cyan
    terraform output -raw ssh_connection
    Write-Host ""
    Write-Host ""
    Write-Host "To check Docker status on server:" -ForegroundColor Cyan
    Write-Host "  docker-compose ps" -ForegroundColor White
    Write-Host "  docker-compose logs -f" -ForegroundColor White
    Write-Host ""
    Write-Host "Deployment successful!" -ForegroundColor Green
} else {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    Write-Host "To deploy later, run: terraform apply tfplan" -ForegroundColor Gray
}
