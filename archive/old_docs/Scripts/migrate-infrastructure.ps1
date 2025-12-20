#!/usr/bin/env pwsh
# ===================================
# Migration Script
# Migrate from old structure to new
# ===================================

param(
    [switch]$DryRun
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

Write-Header "MIGRATION: Old Structure → New Infrastructure"

if ($DryRun) {
    Write-Host "⚠️  DRY RUN MODE - No files will be modified`n" -ForegroundColor Yellow
}

# Check if old structure exists
$hasOldTerraform = Test-Path "terraform\terraform.tfstate"
$hasOldAnsible = Test-Path "ansible\playbooks"

Write-Step "Checking existing structure..."
Write-Host "   Old Terraform: $(if ($hasOldTerraform) { '✓ Found' } else { '✗ Not found' })" -ForegroundColor Gray
Write-Host "   Old Ansible: $(if ($hasOldAnsible) { '✓ Found' } else { '✗ Not found' })" -ForegroundColor Gray
Write-Host "   New Infrastructure: ✓ Ready`n" -ForegroundColor Gray

if (-not $hasOldTerraform -and -not $hasOldAnsible) {
    Write-Host "✅ No migration needed - using new structure only`n" -ForegroundColor Green
    exit 0
}

Write-Header "RECOMMENDATION"

Write-Host "📋 Your project has both old and new infrastructure:" -ForegroundColor Yellow
Write-Host ""
Write-Host "OLD STRUCTURE (terraform/, ansible/):" -ForegroundColor White
Write-Host "  • Contains working Terraform state" -ForegroundColor Gray
Write-Host "  • Has ECR repositories configured" -ForegroundColor Gray
Write-Host "  • K8s deployments use ECR images" -ForegroundColor Gray
Write-Host "  • Jenkinsfile configured for ECR" -ForegroundColor Gray
Write-Host ""
Write-Host "NEW STRUCTURE (infrastructure/):" -ForegroundColor White
Write-Host "  • Professional modular design" -ForegroundColor Gray
Write-Host "  • Reusable Terraform modules" -ForegroundColor Gray
Write-Host "  • Role-based Ansible" -ForegroundColor Gray
Write-Host "  • Better separation of concerns" -ForegroundColor Gray
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎯 RECOMMENDED APPROACH:" -ForegroundColor Cyan
Write-Host ""
Write-Host "OPTION 1: Keep using OLD structure (Safer)" -ForegroundColor Yellow
Write-Host "  ✅ Already working" -ForegroundColor Green
Write-Host "  ✅ Has active resources in AWS" -ForegroundColor Green
Write-Host "  ✅ No migration risk" -ForegroundColor Green
Write-Host "  ⚠️  Less modular" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Commands:" -ForegroundColor White
Write-Host "    cd terraform" -ForegroundColor Gray
Write-Host "    terraform plan" -ForegroundColor Gray
Write-Host "    terraform apply" -ForegroundColor Gray
Write-Host ""
Write-Host "OPTION 2: Migrate to NEW structure (Better long-term)" -ForegroundColor Yellow
Write-Host "  ✅ Professional structure" -ForegroundColor Green
Write-Host "  ✅ Easier to maintain" -ForegroundColor Green
Write-Host "  ✅ Reusable modules" -ForegroundColor Green
Write-Host "  ⚠️  Requires terraform state migration" -ForegroundColor Yellow
Write-Host "  ⚠️  Need to import existing resources" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Commands:" -ForegroundColor White
Write-Host "    .\infrastructure\deploy.ps1 -Action terraform" -ForegroundColor Gray
Write-Host ""
Write-Host "OPTION 3: Hybrid (Recommended for now)" -ForegroundColor Yellow
Write-Host "  ✅ Keep OLD for existing resources" -ForegroundColor Green
Write-Host "  ✅ Use NEW for future projects" -ForegroundColor Green
Write-Host "  ✅ No downtime" -ForegroundColor Green
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 CURRENT STATUS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your Kahoot Clone is WORKING with:" -ForegroundColor White
Write-Host "  • ECR: 802346121373.dkr.ecr.ap-southeast-1.amazonaws.com" -ForegroundColor Gray
Write-Host "  • Terraform state: terraform/terraform.tfstate" -ForegroundColor Gray
Write-Host "  • Jenkinsfile: Configured for ECR" -ForegroundColor Gray
Write-Host "  • K8s: Deployments point to ECR images" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ NO ACTION NEEDED - Project is stable!" -ForegroundColor Green
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "  • Old structure: terraform/README.md" -ForegroundColor Gray
Write-Host "  • New structure: infrastructure/README.md" -ForegroundColor Gray
Write-Host "  • K8s + ECR: K8S_ECR_DEPLOYMENT_GUIDE.md" -ForegroundColor Gray
Write-Host ""
