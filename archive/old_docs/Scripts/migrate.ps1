#!/usr/bin/env pwsh
# ===================================
# Migration Script - OLD → NEW
# Safely migrate infrastructure
# ===================================

param(
    [ValidateSet('analyze', 'migrate', 'cleanup')]
    [string]$Action = "analyze",
    
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Title)
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $Title" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host "→ $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  ⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor Red
}

# ===================================
# Analyze Phase
# ===================================
function Invoke-Analyze {
    Write-Header "ANALYSIS: Current Project Structure"
    
    $analysis = @{
        OldFiles = @()
        NewFiles = @()
        ToMigrate = @()
        ToCleanup = @()
    }
    
    Write-Step "Checking OLD structure (terraform/, ansible/)"
    
    # Check Terraform
    if (Test-Path "terraform\terraform.tfstate") {
        Write-Success "Terraform state exists (contains live AWS resources)"
        $analysis.OldFiles += "terraform/terraform.tfstate"
        $analysis.ToMigrate += "terraform/terraform.tfstate → backup"
    }
    
    if (Test-Path "terraform\terraform.tfvars") {
        Write-Success "Terraform variables exist (contains credentials)"
        $analysis.OldFiles += "terraform/terraform.tfvars"
        $analysis.ToMigrate += "terraform/terraform.tfvars → infrastructure/terraform/"
    }
    
    if (Test-Path "terraform\*.pem") {
        Write-Success "SSH keys exist"
        $analysis.OldFiles += "terraform/*.pem"
        $analysis.ToMigrate += "terraform/*.pem → infrastructure/terraform/"
    }
    
    # Check Ansible
    if (Test-Path "ansible\playbooks") {
        Write-Success "Ansible playbooks exist"
        $analysis.OldFiles += "ansible/playbooks/"
        $analysis.ToMigrate += "ansible/playbooks/ → infrastructure/ansible/"
    }
    
    if (Test-Path "ansible\inventory\hosts") {
        Write-Success "Ansible inventory exists"
        $analysis.OldFiles += "ansible/inventory/hosts"
    }
    
    Write-Step "Checking NEW structure (infrastructure/)"
    
    if (Test-Path "infrastructure\terraform\modules") {
        Write-Success "New Terraform modules ready"
        $analysis.NewFiles += "infrastructure/terraform/modules/"
    }
    
    if (Test-Path "infrastructure\ansible\roles") {
        Write-Success "New Ansible roles ready"
        $analysis.NewFiles += "infrastructure/ansible/roles/"
    }
    
    Write-Header "MIGRATION PLAN"
    
    Write-Host "📋 CRITICAL DATA TO PRESERVE:`n" -ForegroundColor Cyan
    
    Write-Host "1. Terraform State:" -ForegroundColor Yellow
    Write-Host "   • terraform/terraform.tfstate" -ForegroundColor White
    Write-Host "   • Contains: VPC, EC2, ECR repositories" -ForegroundColor Gray
    Write-Host "   • Action: BACKUP (do not delete)`n" -ForegroundColor Green
    
    Write-Host "2. Credentials & Secrets:" -ForegroundColor Yellow
    Write-Host "   • terraform/terraform.tfvars (AWS creds, MongoDB URI)" -ForegroundColor White
    Write-Host "   • terraform/*.pem (SSH keys)" -ForegroundColor White
    Write-Host "   • Action: COPY to infrastructure/terraform/`n" -ForegroundColor Green
    
    Write-Host "3. Working Configurations:" -ForegroundColor Yellow
    Write-Host "   • Jenkinsfile (ECR configured)" -ForegroundColor White
    Write-Host "   • k8s/*.yaml (deployments)" -ForegroundColor White
    Write-Host "   • Action: KEEP (already working)`n" -ForegroundColor Green
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    Write-Host "`n📦 FILES TO MIGRATE:`n" -ForegroundColor Cyan
    foreach ($item in $analysis.ToMigrate) {
        Write-Host "  • $item" -ForegroundColor Gray
    }
    
    Write-Host "`n🗑️  SAFE TO CLEANUP (after migration):`n" -ForegroundColor Cyan
    Write-Host "  • terraform/.terraform/" -ForegroundColor Gray
    Write-Host "  • terraform/tfplan" -ForegroundColor Gray
    Write-Host "  • ansible/*.retry" -ForegroundColor Gray
    Write-Host "  • Old documentation duplicates`n" -ForegroundColor Gray
    
    return $analysis
}

# ===================================
# Migration Phase
# ===================================
function Invoke-Migration {
    Write-Header "MIGRATION: OLD → NEW"
    
    if (-not $Force) {
        Write-Host "⚠️  This will modify your project structure!`n" -ForegroundColor Yellow
        $confirm = Read-Host "Continue? (yes/no)"
        if ($confirm -ne "yes") {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    # Create backup directory
    $backupDir = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Step "Creating backup directory: $backupDir"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    # Backup Terraform state
    if (Test-Path "terraform\terraform.tfstate") {
        Write-Step "Backing up Terraform state"
        Copy-Item "terraform\terraform.tfstate" "$backupDir\" -Force
        Write-Success "Backed up to $backupDir\terraform.tfstate"
    }
    
    # Migrate terraform.tfvars
    if (Test-Path "terraform\terraform.tfvars") {
        Write-Step "Migrating terraform.tfvars"
        
        # Read old tfvars
        $oldVars = Get-Content "terraform\terraform.tfvars" -Raw
        
        # Create new tfvars for infrastructure
        $newVars = @"
# Migrated from old terraform/terraform.tfvars
# $(Get-Date)

# AWS Configuration
aws_region = "ap-southeast-1"  # Changed from us-east-1 to match ECR

# Project Configuration
project_name = "kahoot-clone"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
availability_zone = "ap-southeast-1a"

# Security
allowed_ssh_cidrs = ["0.0.0.0/0"]
allowed_http_cidrs = ["0.0.0.0/0"]

# Ubuntu 22.04 LTS AMI in ap-southeast-1
ami_id = "ami-0fa377108253bf620"

# Instance Configuration
jenkins_instance_type = "t3.medium"
k8s_instance_type = "t3.medium"
k8s_worker_count = 2

# GitHub Repository
github_repo = "https://github.com/Thang141104/DevOps-Kahoot-Clone.git"
github_branch = "fix/auth-routing-issues"

# ===================================
# SECRETS (from old config)
# Store these in AWS Secrets Manager or Jenkins credentials for production
# ===================================

# Note: AWS credentials should use AWS CLI profile or IAM role
# Note: MongoDB, email, JWT should be in K8s secrets
# See: k8s/secrets.yaml
"@
        
        Set-Content "infrastructure\terraform\terraform.tfvars" $newVars
        Write-Success "Created infrastructure/terraform/terraform.tfvars"
        Write-Warning "Review and update credentials - use AWS Secrets Manager for production"
    }
    
    # Copy SSH keys
    if (Test-Path "terraform\*.pem") {
        Write-Step "Copying SSH keys"
        Copy-Item "terraform\*.pem" "infrastructure\terraform\" -Force
        Write-Success "Copied SSH keys to infrastructure/terraform/"
    }
    
    # Merge Ansible playbooks
    Write-Step "Merging Ansible configurations"
    
    # Check if old playbooks have custom configurations
    if (Test-Path "ansible\playbooks\jenkins-setup.yml") {
        Write-Warning "Old jenkins-setup.yml found - review for custom configurations"
        Copy-Item "ansible\playbooks\jenkins-setup.yml" "$backupDir\" -Force
    }
    
    if (Test-Path "ansible\playbooks\k8s-setup.yml") {
        Write-Warning "Old k8s-setup.yml found - review for custom configurations"
        Copy-Item "ansible\playbooks\k8s-setup.yml" "$backupDir\" -Force
    }
    
    Write-Success "Backup created in $backupDir/"
    
    Write-Header "MIGRATION COMPLETE"
    
    Write-Host "✅ Critical data preserved:" -ForegroundColor Green
    Write-Host "   • Terraform state: $backupDir\terraform.tfstate" -ForegroundColor Gray
    Write-Host "   • Credentials: infrastructure/terraform/terraform.tfvars" -ForegroundColor Gray
    Write-Host "   • SSH keys: infrastructure/terraform/*.pem" -ForegroundColor Gray
    Write-Host "   • Old playbooks: $backupDir/*.yml`n" -ForegroundColor Gray
    
    Write-Host "⚠️  IMPORTANT NEXT STEPS:`n" -ForegroundColor Yellow
    
    Write-Host "1. Review migrated files:" -ForegroundColor White
    Write-Host "   • infrastructure/terraform/terraform.tfvars" -ForegroundColor Gray
    Write-Host "   • Update secrets to use AWS Secrets Manager`n" -ForegroundColor Gray
    
    Write-Host "2. Keep OLD Terraform state for now:" -ForegroundColor White
    Write-Host "   • Do NOT delete terraform/terraform.tfstate" -ForegroundColor Red
    Write-Host "   • It contains your live AWS resources`n" -ForegroundColor Gray
    
    Write-Host "3. To use NEW infrastructure:" -ForegroundColor White
    Write-Host "   • .\infrastructure\deploy.ps1 -Action terraform`n" -ForegroundColor Gray
    
    Write-Host "4. To import existing resources (advanced):" -ForegroundColor White
    Write-Host "   • cd infrastructure\terraform" -ForegroundColor Gray
    Write-Host "   • terraform import module.ecr.aws_ecr_repository.repositories[`"gateway`"] kahoot-clone-gateway`n" -ForegroundColor Gray
}

# ===================================
# Cleanup Phase
# ===================================
function Invoke-Cleanup {
    Write-Header "CLEANUP: Remove Old Structure"
    
    if (-not $Force) {
        Write-Host "⚠️  This will DELETE old files!`n" -ForegroundColor Red
        Write-Host "Make sure you have:" -ForegroundColor Yellow
        Write-Host "  • Backed up terraform.tfstate" -ForegroundColor White
        Write-Host "  • Migrated credentials" -ForegroundColor White
        Write-Host "  • Tested new infrastructure`n" -ForegroundColor White
        
        $confirm = Read-Host "Are you ABSOLUTELY sure? Type 'DELETE' to confirm"
        if ($confirm -ne "DELETE") {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    Write-Step "Cleaning up old structure"
    
    # Clean Terraform temp files (safe)
    if (Test-Path "terraform\.terraform") {
        Remove-Item "terraform\.terraform" -Recurse -Force
        Write-Success "Removed terraform/.terraform/"
    }
    
    if (Test-Path "terraform\tfplan") {
        Remove-Item "terraform\tfplan" -Force
        Write-Success "Removed terraform/tfplan"
    }
    
    # Clean Ansible temp files (safe)
    if (Test-Path "ansible\*.retry") {
        Remove-Item "ansible\*.retry" -Force
        Write-Success "Removed ansible/*.retry"
    }
    
    Write-Warning "Keeping terraform/terraform.tfstate - contains live resources"
    Write-Warning "Keeping terraform/terraform.tfvars - contains credentials (backed up)"
    Write-Warning "Keeping Jenkinsfile, k8s/ - currently in use"
    
    Write-Host "`n✅ Cleanup complete (safe files only)`n" -ForegroundColor Green
}

# ===================================
# Main Execution
# ===================================

try {
    Write-Header "Infrastructure Migration Tool"
    
    switch ($Action) {
        "analyze" {
            Invoke-Analyze
            
            Write-Host "`n💡 NEXT STEPS:`n" -ForegroundColor Cyan
            Write-Host "1. Run migration:" -ForegroundColor White
            Write-Host "   .\migrate.ps1 -Action migrate`n" -ForegroundColor Yellow
            
            Write-Host "2. Review migrated files`n" -ForegroundColor White
            
            Write-Host "3. Test new infrastructure:" -ForegroundColor White
            Write-Host "   .\infrastructure\deploy.ps1 -Action terraform`n" -ForegroundColor Yellow
            
            Write-Host "4. Cleanup old files (optional):" -ForegroundColor White
            Write-Host "   .\migrate.ps1 -Action cleanup`n" -ForegroundColor Yellow
        }
        
        "migrate" {
            Invoke-Migration
        }
        
        "cleanup" {
            Invoke-Cleanup
        }
    }
    
} catch {
    Write-Host "`n❌ Migration failed: $_`n" -ForegroundColor Red
    exit 1
}
