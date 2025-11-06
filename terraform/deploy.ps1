# Terraform Deployment Script - Simplified

Write-Host "=== Kahoot Clone Deployment ===" -ForegroundColor Cyan

# Check terraform.tfvars
if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "ERROR: terraform.tfvars not found!" -ForegroundColor Red
    Write-Host "Please create it from terraform.tfvars.example" -ForegroundColor Yellow
    exit 1
}

# Initialize
Write-Host "`n[1/4] Initializing..." -ForegroundColor Cyan
terraform init
if ($LASTEXITCODE -ne 0) { exit 1 }

# Validate
Write-Host "`n[2/4] Validating..." -ForegroundColor Cyan
terraform validate
if ($LASTEXITCODE -ne 0) { exit 1 }

# Plan
Write-Host "`n[3/4] Planning..." -ForegroundColor Cyan
terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) { exit 1 }

# Confirm
Write-Host "`nReady to deploy. Continue? (yes/no): " -ForegroundColor Yellow -NoNewline
$confirm = Read-Host
if ($confirm -ne "yes") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

# Apply
Write-Host "`n[4/4] Deploying (5-10 minutes)..." -ForegroundColor Cyan
terraform apply tfplan
if ($LASTEXITCODE -ne 0) { exit 1 }

# Success
Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
terraform output
Write-Host "`nWait 2-3 minutes for services to start." -ForegroundColor Yellow
