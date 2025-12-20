#!/usr/bin/env pwsh
# ================================
# Complete Deployment Workflow
# ================================

param(
    [ValidateSet('all', 'terraform', 'jenkins', 'k8s', 'verify')]
    [string]$Step = "all",
    
    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📍 $Message" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
}

function Invoke-Terraform {
    Write-Step "STEP 1: Terraform Infrastructure"
    
    Write-Host "🏗️  Creating AWS infrastructure..." -ForegroundColor Yellow
    Write-Host "   - VPC & Networking" -ForegroundColor Gray
    Write-Host "   - ECR Repositories (7 empty repos)" -ForegroundColor Gray
    Write-Host "   - IAM Roles & Policies" -ForegroundColor Gray
    Write-Host "   - Jenkins EC2 (with ECR access)" -ForegroundColor Gray
    Write-Host "   - K8s Cluster (1 master + 2 workers)" -ForegroundColor Gray
    Write-Host "   - SonarQube namespace (ready for deployment)`n" -ForegroundColor Gray
    
    cd terraform
    
    # Initialize if needed
    if (-not (Test-Path ".terraform")) {
        Write-Host "📦 Initializing Terraform..." -ForegroundColor Yellow
        terraform init
        if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }
    }
    
    # Plan
    Write-Host "`n📋 Planning infrastructure changes..." -ForegroundColor Yellow
    terraform plan -out=tfplan
    if ($LASTEXITCODE -ne 0) { throw "Terraform plan failed" }
    
    # Apply
    if ($AutoApprove) {
        Write-Host "`n🚀 Applying infrastructure changes..." -ForegroundColor Green
        terraform apply tfplan
    } else {
        Write-Host "`n⚠️  Review the plan above." -ForegroundColor Yellow
        $confirm = Read-Host "Apply these changes? (yes/no)"
        if ($confirm -eq "yes") {
            terraform apply tfplan
        } else {
            Write-Host "Cancelled." -ForegroundColor Yellow
            cd ..
            return $false
        }
    }
    
    if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" }
    
    # Get outputs
    Write-Host "`n✅ Infrastructure created!" -ForegroundColor Green
    Write-Host "`n📋 Infrastructure Details:" -ForegroundColor Cyan
    
    $jenkinsIp = terraform output -raw jenkins_public_ip
    $jenkinsUrl = terraform output -raw jenkins_url
    $k8sMasterIp = terraform output -raw k8s_master_public_ip
    $ecrRegistry = terraform output -raw ecr_registry_url
    
    Write-Host "   Jenkins: $jenkinsUrl" -ForegroundColor White
    Write-Host "   K8s Master: $k8sMasterIp" -ForegroundColor White
    Write-Host "   ECR Registry: $ecrRegistry" -ForegroundColor White
    
    # Save to file for later use
    @{
        jenkins_ip = $jenkinsIp
        jenkins_url = $jenkinsUrl
        k8s_master_ip = $k8sMasterIp
        ecr_registry = $ecrRegistry
    } | ConvertTo-Json | Out-File "../.deployment-info.json"
    
    cd ..
    
    Write-Host "`n⏰ Infrastructure created, but services NOT running yet!" -ForegroundColor Yellow
    Write-Host "`n📋 Why services are not running:" -ForegroundColor Cyan
    Write-Host "   1. ECR repositories are EMPTY (no Docker images)" -ForegroundColor Gray
    Write-Host "   2. Jenkins needs to BUILD images first" -ForegroundColor Gray
    Write-Host "   3. Then K8s can DEPLOY from ECR" -ForegroundColor Gray
    
    Write-Host "`n⏳ Waiting 5 minutes for EC2 instances to fully initialize..." -ForegroundColor Yellow
    Write-Host "   (Jenkins installation, K8s cluster setup)..." -ForegroundColor Gray
    
    for ($i = 300; $i -gt 0; $i -= 30) {
        Write-Host "   $i seconds remaining..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
    }
    
    Write-Host "`n✅ Infrastructure ready!" -ForegroundColor Green
    Write-Host "⚠️  But SERVICES are NOT running yet." -ForegroundColor Yellow
    Write-Host "   Next: Run Jenkins build to create Docker images." -ForegroundColor White
    
    return $true
}

function Invoke-JenkinsBuild {
    Write-Step "STEP 2: Jenkins Build & Push Images"
    
    if (-not (Test-Path ".deployment-info.json")) {
        Write-Host "❌ No deployment info found. Run terraform first." -ForegroundColor Red
        return $false
    }
    
    $info = Get-Content ".deployment-info.json" | ConvertFrom-Json
    
    Write-Host "🏗️  Jenkins will build Docker images and push to ECR" -ForegroundColor Yellow
    Write-Host "`n📋 Jenkins Setup:" -ForegroundColor Cyan
    Write-Host "   1. Open Jenkins: $($info.jenkins_url)" -ForegroundColor White
    Write-Host "   2. Get initial admin password:" -ForegroundColor White
    Write-Host "      ssh -i ~/.ssh/kahoot-key.pem ubuntu@$($info.jenkins_ip)" -ForegroundColor Gray
    Write-Host "      sudo cat /var/lib/jenkins/secrets/initialAdminPassword" -ForegroundColor Gray
    Write-Host "   3. Install suggested plugins" -ForegroundColor White
    Write-Host "   4. Create admin user" -ForegroundColor White
    Write-Host "   5. Create new Pipeline job:" -ForegroundColor White
    Write-Host "      - Pipeline from SCM" -ForegroundColor Gray
    Write-Host "      - Git: https://github.com/YOUR_REPO.git" -ForegroundColor Gray
    Write-Host "      - Branch: fix/auth-routing-issues" -ForegroundColor Gray
    Write-Host "      - Script Path: Jenkinsfile" -ForegroundColor Gray
    Write-Host "   6. Click 'Build Now'" -ForegroundColor White
    Write-Host "`n⏰ Expected build time: ~15-20 minutes (first build)" -ForegroundColor Yellow
    Write-Host "   (Next builds will be faster with BuildKit cache ~3-5 minutes)" -ForegroundColor Gray
    
    Write-Host "`n📦 After build completes, ECR will have 7 images:" -ForegroundColor Cyan
    Write-Host "   - kahoot-clone-gateway" -ForegroundColor Gray
    Write-Host "   - kahoot-clone-auth" -ForegroundColor Gray
    Write-Host "   - kahoot-clone-user" -ForegroundColor Gray
    Write-Host "   - kahoot-clone-quiz" -ForegroundColor Gray
    Write-Host "   - kahoot-clone-game" -ForegroundColor Gray
    Write-Host "   - kahoot-clone-analytics" -ForegroundColor Gray
    Write-Host "   - kahoot-clone-frontend" -ForegroundColor Gray
    
    Write-Host "`n✋ Press ENTER when Jenkins build is complete..." -ForegroundColor Yellow
    Read-Host
    
    # Verify ECR has images
    Write-Host "🔍 Verifying ECR images..." -ForegroundColor Yellow
    $repos = aws ecr describe-repositories --query 'repositories[].repositoryName' --output json | ConvertFrom-Json
    
    $hasImages = $true
    foreach ($repo in $repos) {
        $images = aws ecr list-images --repository-name $repo --query 'imageIds | length(@)' --output text
        if ($images -gt 0) {
            Write-Host "   ✅ $repo : $images images" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $repo : No images" -ForegroundColor Red
            $hasImages = $false
        }
    }
    
    return $hasImages
}

function Invoke-K8sDeploy {
    Write-Step "STEP 3: Deploy to Kubernetes"
    
    if (-not (Test-Path ".deployment-info.json")) {
        Write-Host "❌ No deployment info found. Run terraform first." -ForegroundColor Red
        return $false
    }
    
    $info = Get-Content ".deployment-info.json" | ConvertFrom-Json
    
    Write-Host "☸️  Deploying to Kubernetes cluster..." -ForegroundColor Yellow
    Write-Host "`n📋 K8s Deployment Steps:" -ForegroundColor Cyan
    
    Write-Host "`n1️⃣  SSH into K8s Master:" -ForegroundColor Cyan
    Write-Host "   ssh -i ~/.ssh/kahoot-key.pem ubuntu@$($info.k8s_master_ip)" -ForegroundColor Gray
    
    Write-Host "`n2️⃣  Clone repo and deploy:" -ForegroundColor Cyan
    Write-Host "   git clone https://github.com/YOUR_REPO.git" -ForegroundColor Gray
    Write-Host "   cd DevOps-Kahoot-Clone" -ForegroundColor Gray
    Write-Host "   kubectl apply -f k8s/namespace.yaml" -ForegroundColor Gray
    Write-Host "   kubectl apply -f k8s/secrets.yaml" -ForegroundColor Gray
    Write-Host "   kubectl apply -f k8s/configmap.yaml" -ForegroundColor Gray
    Write-Host "   kubectl apply -f k8s/" -ForegroundColor Gray
    
    Write-Host "`n3️⃣  Wait for pods to be ready:" -ForegroundColor Cyan
    Write-Host "   kubectl get pods -n kahoot-clone -w" -ForegroundColor Gray
    
    Write-Host "`n4️⃣  Check services:" -ForegroundColor Cyan
    Write-Host "   kubectl get svc -n kahoot-clone" -ForegroundColor Gray
    
    Write-Host "`n⏰ Expected deployment time: ~5-10 minutes" -ForegroundColor Yellow
    Write-Host "   (K8s will pull images from ECR - very fast in same region)" -ForegroundColor Gray
    
    Write-Host "`n✅ After deployment, access application at:" -ForegroundColor Green
    Write-Host "   Frontend:   http://$($info.k8s_master_ip):30006" -ForegroundColor White
    Write-Host "   Gateway:    http://$($info.k8s_master_ip):30000" -ForegroundColor White
    Write-Host "   Prometheus: http://$($info.k8s_master_ip):30090" -ForegroundColor White
    Write-Host "   Grafana:    http://$($info.k8s_master_ip):30300" -ForegroundColor White
    
    return $true
}

function Invoke-Verify {
    Write-Step "STEP 4: Verify Deployment"
    
    if (-not (Test-Path ".deployment-info.json")) {
        Write-Host "❌ No deployment info found." -ForegroundColor Red
        return
    }
    
    Write-Host "🔍 Running infrastructure health check..." -ForegroundColor Yellow
    .\check-infrastructure.ps1
}

# Main execution
try {
    Write-Host "🚀 DevOps Kahoot Clone - Complete Deployment" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    
    switch ($Step) {
        "all" {
            if (Invoke-Terraform) {
                if (Invoke-JenkinsBuild) {
                    if (Invoke-K8sDeploy) {
                        Invoke-Verify
                        Write-Host "`n🎉 DEPLOYMENT COMPLETE!" -ForegroundColor Green
                    }
                }
            }
        }
        "terraform" { Invoke-Terraform }
        "jenkins" { Invoke-JenkinsBuild }
        "k8s" { Invoke-K8sDeploy }
        "verify" { Invoke-Verify }
    }
    
} catch {
    Write-Host "`n❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
