# Jenkins Quick Setup Script
# Run this in PowerShell after infrastructure is deployed

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Jenkins CI/CD Quick Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Terraform is installed
if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Terraform is not installed!" -ForegroundColor Red
    Write-Host "Please install Terraform from: https://www.terraform.io/downloads" -ForegroundColor Yellow
    exit 1
}

# Check if AWS CLI is configured
if (!(Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "❌ AWS CLI is not installed!" -ForegroundColor Red
    Write-Host "Please install AWS CLI from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Prerequisites check passed!" -ForegroundColor Green
Write-Host ""

# Navigate to terraform directory
Set-Location terraform

Write-Host "Step 1: Initializing Terraform..." -ForegroundColor Yellow
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform init failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Terraform initialized!" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Planning infrastructure deployment..." -ForegroundColor Yellow
terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform plan failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Infrastructure plan created!" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Deploying infrastructure..." -ForegroundColor Yellow
Write-Host "This will take approximately 5-10 minutes..." -ForegroundColor Cyan
terraform apply tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform apply failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Infrastructure deployed successfully!" -ForegroundColor Green
Write-Host ""

# Get outputs
$jenkinsIP = terraform output -raw jenkins_public_ip
$jenkinsURL = terraform output -raw jenkins_url
$sonarqubeURL = terraform output -raw sonarqube_url
$k8sIP = terraform output -raw k8s_master_ip
$k8sAPI = terraform output -raw k8s_api_endpoint

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✅ DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Jenkins Information:" -ForegroundColor Yellow
Write-Host "  URL: $jenkinsURL" -ForegroundColor White
Write-Host "  IP: $jenkinsIP" -ForegroundColor White
Write-Host ""
Write-Host "📊 SonarQube Information:" -ForegroundColor Yellow
Write-Host "  URL: $sonarqubeURL" -ForegroundColor White
Write-Host "  Default Login: admin/admin" -ForegroundColor White
Write-Host ""
Write-Host "☸️  Kubernetes Information:" -ForegroundColor Yellow
Write-Host "  Master IP: $k8sIP" -ForegroundColor White
Write-Host "  API Endpoint: $k8sAPI" -ForegroundColor White
Write-Host ""
Write-Host "⏳ Services are starting up (this takes ~5 minutes)..." -ForegroundColor Cyan
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Wait 5 minutes for services to fully start" -ForegroundColor White
Write-Host ""
Write-Host "2. Get Jenkins initial admin password:" -ForegroundColor White
Write-Host "   ssh -i kahoot-key.pem ubuntu@$jenkinsIP" -ForegroundColor Cyan
Write-Host "   /home/ubuntu/show-info.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Access Jenkins at: $jenkinsURL" -ForegroundColor White
Write-Host ""
Write-Host "4. Configure Jenkins:" -ForegroundColor White
Write-Host "   - Install suggested plugins" -ForegroundColor Gray
Write-Host "   - Add Docker Hub credentials (dockerhub-credentials)" -ForegroundColor Gray
Write-Host "   - Add AWS credentials (aws-credentials)" -ForegroundColor Gray
Write-Host "   - Add SonarQube token (sonarqube-token)" -ForegroundColor Gray
Write-Host "   - Add Snyk token (snyk-token)" -ForegroundColor Gray
Write-Host "   - Add Kubernetes config (kubeconfig)" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Get Kubernetes config:" -ForegroundColor White
Write-Host "   ssh -i kahoot-key.pem ubuntu@$k8sIP" -ForegroundColor Cyan
Write-Host "   /home/ubuntu/get-kubeconfig.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "6. Create Jenkins Pipeline:" -ForegroundColor White
Write-Host "   - New Item → Pipeline" -ForegroundColor Gray
Write-Host "   - Pipeline from SCM → Git" -ForegroundColor Gray
Write-Host "   - Repository: https://github.com/Thang141104/DevOps-Kahoot-Clone.git" -ForegroundColor Gray
Write-Host "   - Script Path: Jenkinsfile" -ForegroundColor Gray
Write-Host ""
Write-Host "7. Build the pipeline!" -ForegroundColor White
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "📖 For detailed instructions, see:" -ForegroundColor Yellow
Write-Host "   JENKINS_CICD_README.md" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Create connection info file
$infoContent = @"
# Jenkins CI/CD Connection Information
Generated: $(Get-Date)

## Jenkins
- URL: $jenkinsURL
- IP: $jenkinsIP
- SSH: ssh -i kahoot-key.pem ubuntu@$jenkinsIP

## SonarQube
- URL: $sonarqubeURL
- Default Login: admin/admin

## Kubernetes
- Master IP: $k8sIP
- API: $k8sAPI
- SSH: ssh -i kahoot-key.pem ubuntu@$k8sIP

## AWS Credentials
- Get from AWS IAM Console
- Configure in Jenkins: Manage Jenkins > Credentials
- Region: us-east-1

## Next Steps
1. Wait 5 minutes for services to start
2. Get Jenkins password: /home/ubuntu/show-info.sh
3. Configure Jenkins with credentials
4. Get kubeconfig: /home/ubuntu/get-kubeconfig.sh
5. Create and run pipeline

See JENKINS_CICD_README.md for complete guide.
"@

Set-Content -Path "CONNECTION_INFO.txt" -Value $infoContent
Write-Host "✅ Connection info saved to: terraform/CONNECTION_INFO.txt" -ForegroundColor Green
Write-Host ""
