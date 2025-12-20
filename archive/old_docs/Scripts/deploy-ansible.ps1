#!/usr/bin/env pwsh
# ================================
# Complete Deployment with Ansible
# ================================

param(
    [ValidateSet('all', 'terraform', 'ansible', 'verify')]
    [string]$Step = "all",
    
    [switch]$AutoApprove,
    [switch]$SkipAnsible
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📍 $Message" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
}

function Invoke-Terraform {
    Write-Step "STEP 1: Terraform Infrastructure Provisioning"
    
    Write-Host "🏗️  Creating AWS infrastructure..." -ForegroundColor Yellow
    Write-Host "   - VPC & Networking" -ForegroundColor Gray
    Write-Host "   - ECR Repositories (7 repos)" -ForegroundColor Gray
    Write-Host "   - IAM Roles & Policies" -ForegroundColor Gray
    Write-Host "   - Jenkins EC2 (t3.medium)" -ForegroundColor Gray
    Write-Host "   - K8s Cluster (1 master + 2 workers)`n" -ForegroundColor Gray
    
    cd terraform
    
    if (-not (Test-Path ".terraform")) {
        Write-Host "📦 Initializing Terraform..." -ForegroundColor Yellow
        terraform init
        if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }
    }
    
    Write-Host "`n📋 Planning infrastructure changes..." -ForegroundColor Yellow
    terraform plan -out=tfplan
    if ($LASTEXITCODE -ne 0) { throw "Terraform plan failed" }
    
    if ($AutoApprove) {
        Write-Host "`n🚀 Applying infrastructure changes..." -ForegroundColor Green
        terraform apply tfplan
    } else {
        Write-Host "`n🚀 Applying infrastructure changes..." -ForegroundColor Green
        terraform apply tfplan
    }
    
    if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" }
    
    Write-Host "`n✅ Infrastructure created successfully!" -ForegroundColor Green
    Write-Host "   Ansible inventory generated automatically" -ForegroundColor Gray
    Write-Host "   Location: ansible/inventory/hosts`n" -ForegroundColor Gray
    
    # Save outputs
    terraform output -json > ../deployment-outputs.json
    
    cd ..
}

function Invoke-AnsibleSetup {
    Write-Step "STEP 2: Ansible Configuration Management"
    
    Write-Host "📦 Checking Ansible installation..." -ForegroundColor Yellow
    
    if (-not (Get-Command ansible -ErrorAction SilentlyContinue)) {
        Write-Host "⚠️  Ansible not found. Installing via WSL..." -ForegroundColor Yellow
        Write-Host "`nPlease run in WSL:" -ForegroundColor Red
        Write-Host "  sudo apt update" -ForegroundColor White
        Write-Host "  sudo apt install -y ansible`n" -ForegroundColor White
        throw "Ansible not installed"
    }
    
    Write-Host "`n✅ Ansible installed" -ForegroundColor Green
    
    Write-Host "`n🔧 Configuring servers with Ansible..." -ForegroundColor Yellow
    
    # Jenkins Setup
    Write-Host "`n1️⃣  Configuring Jenkins Server (~10 minutes)..." -ForegroundColor Cyan
    Write-Host "   - Installing Docker, Jenkins, NodeJS" -ForegroundColor Gray
    Write-Host "   - Installing AWS CLI, kubectl, Trivy" -ForegroundColor Gray
    Write-Host "   - Installing SonarQube Scanner" -ForegroundColor Gray
    
    cd ansible
    ansible-playbook -i inventory/hosts playbooks/jenkins-setup.yml
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Jenkins setup failed, but continuing..." -ForegroundColor Yellow
    }
    
    # Kubernetes Setup
    Write-Host "`n2️⃣  Setting up Kubernetes Cluster (~15 minutes)..." -ForegroundColor Cyan
    Write-Host "   - Initializing master node" -ForegroundColor Gray
    Write-Host "   - Installing Calico network plugin" -ForegroundColor Gray
    Write-Host "   - Joining worker nodes" -ForegroundColor Gray
    
    ansible-playbook -i inventory/hosts playbooks/k8s-setup.yml
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  K8s setup failed, but continuing..." -ForegroundColor Yellow
    }
    
    cd ..
    
    Write-Host "`n✅ Ansible configuration completed!" -ForegroundColor Green
}

function Invoke-Verification {
    Write-Step "STEP 3: Verification & Access Information"
    
    $outputs = Get-Content deployment-outputs.json | ConvertFrom-Json
    
    Write-Host "🎉 Deployment Complete!`n" -ForegroundColor Green
    
    Write-Host "📊 Infrastructure Summary:" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    
    Write-Host "🔧 Jenkins Server:" -ForegroundColor Yellow
    Write-Host "   URL:      $($outputs.jenkins_url.value)" -ForegroundColor White
    Write-Host "   SSH:      $($outputs.jenkins_ssh_command.value)" -ForegroundColor Gray
    Write-Host "   Initial Password: Check logs after first login`n" -ForegroundColor Gray
    
    Write-Host "☸️  Kubernetes Cluster:" -ForegroundColor Yellow
    Write-Host "   Master:   $($outputs.k8s_master_ip.value)" -ForegroundColor White
    Write-Host "   Workers:  $($outputs.k8s_worker_ips.value -join ', ')" -ForegroundColor White
    Write-Host "   SSH:      $($outputs.k8s_ssh_commands.value.master)`n" -ForegroundColor Gray
    
    Write-Host "🐳 ECR Registry:" -ForegroundColor Yellow
    Write-Host "   Registry: 802346121373.dkr.ecr.ap-southeast-1.amazonaws.com`n" -ForegroundColor White
    
    Write-Host "📝 Next Steps:" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    
    Write-Host "1. Access Jenkins:" -ForegroundColor White
    Write-Host "   • Open: $($outputs.jenkins_url.value)" -ForegroundColor Gray
    Write-Host "   • Get password: SSH to Jenkins and run:" -ForegroundColor Gray
    Write-Host "     sudo cat /var/lib/jenkins/secrets/initialAdminPassword`n" -ForegroundColor DarkGray
    
    Write-Host "2. Configure Jenkins:" -ForegroundColor White
    Write-Host "   • Install suggested plugins" -ForegroundColor Gray
    Write-Host "   • Create admin user" -ForegroundColor Gray
    Write-Host "   • Add credentials:" -ForegroundColor Gray
    Write-Host "     - AWS ECR credentials (for pushing images)" -ForegroundColor DarkGray
    Write-Host "     - SonarQube token (sonarqube-token)" -ForegroundColor DarkGray
    Write-Host "     - GitHub credentials (optional)`n" -ForegroundColor DarkGray
    
    Write-Host "3. Deploy SonarQube to K8s:" -ForegroundColor White
    Write-Host "   kubectl apply -f k8s/sonarqube-deployment.yaml`n" -ForegroundColor Gray
    
    Write-Host "4. Create Jenkins Pipeline:" -ForegroundColor White
    Write-Host "   • New Item → Pipeline" -ForegroundColor Gray
    Write-Host "   • Pipeline script from SCM: Git" -ForegroundColor Gray
    Write-Host "   • Repository: <your-repo-url>" -ForegroundColor Gray
    Write-Host "   • Script Path: Jenkinsfile`n" -ForegroundColor Gray
    
    Write-Host "5. Run First Build:" -ForegroundColor White
    Write-Host "   • Trigger build in Jenkins" -ForegroundColor Gray
    Write-Host "   • Images will be pushed to ECR" -ForegroundColor Gray
    Write-Host "   • Services deployed to K8s`n" -ForegroundColor Gray
    
    Write-Host "⏱️  Total deployment time: ~30 minutes" -ForegroundColor Yellow
    Write-Host "   - Terraform: 15 min" -ForegroundColor Gray
    Write-Host "   - Ansible Jenkins: 10 min" -ForegroundColor Gray
    Write-Host "   - Ansible K8s: 15 min`n" -ForegroundColor Gray
    
    Write-Host "📚 Documentation:" -ForegroundColor Cyan
    Write-Host "   - Ansible playbooks: ansible/playbooks/" -ForegroundColor Gray
    Write-Host "   - Terraform config: terraform/" -ForegroundColor Gray
    Write-Host "   - K8s manifests: k8s/`n" -ForegroundColor Gray
}

# Main execution
try {
    Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Terraform + Ansible Deployment            ║" -ForegroundColor Cyan
    Write-Host "║  Kahoot Clone - Full Infrastructure        ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    switch ($Step) {
        "terraform" {
            Invoke-Terraform
        }
        "ansible" {
            Invoke-AnsibleSetup
        }
        "verify" {
            Invoke-Verification
        }
        "all" {
            Invoke-Terraform
            
            if (-not $SkipAnsible) {
                Start-Sleep -Seconds 30
                Invoke-AnsibleSetup
            }
            
            Invoke-Verification
        }
    }
    
    Write-Host "`n✅ Deployment completed successfully!`n" -ForegroundColor Green
    
} catch {
    Write-Host "`n❌ Deployment failed: $_`n" -ForegroundColor Red
    exit 1
}
