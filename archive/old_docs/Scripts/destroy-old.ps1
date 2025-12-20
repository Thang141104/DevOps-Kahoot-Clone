#!/usr/bin/env pwsh
# ===================================
# DESTROY OLD INFRASTRUCTURE & CLEANUP
# Safe removal of old structure
# ===================================

param(
    [ValidateSet('check', 'destroy', 'cleanup', 'all')]
    [string]$Action = "check",
    
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Title)
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║  $Title" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Red
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
# Check Phase
# ===================================
function Invoke-Check {
    Write-Header "CHECK: What Will Be Destroyed"
    
    $results = @{
        HasState = $false
        HasResources = $false
        ResourceCount = 0
        HasFiles = $false
        FileCount = 0
    }
    
    # Check Terraform state
    if (Test-Path "terraform\terraform.tfstate") {
        Write-Step "Checking Terraform state..."
        $results.HasState = $true
        
        try {
            $state = Get-Content "terraform\terraform.tfstate" | ConvertFrom-Json
            if ($state.resources -and $state.resources.Count -gt 0) {
                $results.HasResources = $true
                $results.ResourceCount = $state.resources.Count
                
                Write-Host "`n📦 AWS Resources to be DESTROYED:`n" -ForegroundColor Red
                
                $state.resources | ForEach-Object {
                    Write-Host "  • $($_.type): $($_.name)" -ForegroundColor Yellow
                }
                
                Write-Host ""
            } else {
                Write-Success "No AWS resources found in state"
            }
        } catch {
            Write-Warning "Could not parse Terraform state"
        }
    } else {
        Write-Success "No Terraform state found - nothing to destroy"
    }
    
    # Check files
    Write-Step "Checking old structure files..."
    
    $oldFiles = @()
    
    if (Test-Path "terraform") {
        $tfFiles = Get-ChildItem "terraform" -Recurse -File | Measure-Object
        $oldFiles += "terraform/ ($($tfFiles.Count) files)"
        $results.FileCount += $tfFiles.Count
    }
    
    if (Test-Path "ansible") {
        $ansibleFiles = Get-ChildItem "ansible" -Recurse -File | Measure-Object
        $oldFiles += "ansible/ ($($ansibleFiles.Count) files)"
        $results.FileCount += $ansibleFiles.Count
    }
    
    if ($oldFiles.Count -gt 0) {
        $results.HasFiles = $true
        Write-Host "`n📁 Files to be REMOVED:`n" -ForegroundColor Yellow
        foreach ($item in $oldFiles) {
            Write-Host "  • $item" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # Summary
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "`n📊 SUMMARY:`n" -ForegroundColor Cyan
    
    if ($results.HasResources) {
        Write-Host "  ⚠️  AWS Resources: $($results.ResourceCount) resources will be DESTROYED" -ForegroundColor Red
    } else {
        Write-Host "  ✓ AWS Resources: None to destroy" -ForegroundColor Green
    }
    
    if ($results.HasFiles) {
        Write-Host "  ⚠️  Files: $($results.FileCount) files will be ARCHIVED" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ Files: None to cleanup" -ForegroundColor Green
    }
    
    Write-Host ""
    
    return $results
}

# ===================================
# Destroy Phase
# ===================================
function Invoke-Destroy {
    Write-Header "DESTROY: AWS Resources"
    
    if (-not (Test-Path "terraform\terraform.tfstate")) {
        Write-Success "No Terraform state found - nothing to destroy"
        return
    }
    
    if (-not $Force) {
        Write-Host "⚠️  THIS WILL PERMANENTLY DELETE AWS RESOURCES!`n" -ForegroundColor Red
        Write-Host "Resources that will be destroyed:" -ForegroundColor Yellow
        Write-Host "  • VPC, Subnets, Internet Gateway" -ForegroundColor Gray
        Write-Host "  • EC2 instances (Jenkins, K8s Master, Workers)" -ForegroundColor Gray
        Write-Host "  • ECR repositories" -ForegroundColor Gray
        Write-Host "  • Security groups, IAM roles" -ForegroundColor Gray
        Write-Host "  • SSH keys`n" -ForegroundColor Gray
        
        $confirm = Read-Host "Type 'DESTROY' to confirm"
        if ($confirm -ne "DESTROY") {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    Write-Step "Running Terraform destroy..."
    
    Set-Location "terraform"
    
    try {
        # Initialize Terraform
        Write-Host "`n  Initializing Terraform..." -ForegroundColor Gray
        terraform init -input=false
        
        # Destroy resources
        Write-Host "  Destroying AWS resources..." -ForegroundColor Gray
        terraform destroy -auto-approve
        
        Write-Success "AWS resources destroyed successfully"
        
    } catch {
        Write-Error "Terraform destroy failed: $_"
        throw
    } finally {
        Set-Location ".."
    }
}

# ===================================
# Cleanup Phase
# ===================================
function Invoke-Cleanup {
    Write-Header "CLEANUP: Remove Old Files"
    
    if (-not $Force) {
        Write-Host "⚠️  This will ARCHIVE old structure files`n" -ForegroundColor Yellow
        
        $confirm = Read-Host "Continue? (yes/no)"
        if ($confirm -ne "yes") {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    # Create archive directory
    $archiveDir = "archive_old_structure_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Step "Creating archive directory: $archiveDir"
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    
    # Move old structure
    if (Test-Path "terraform") {
        Write-Step "Archiving terraform/"
        Move-Item "terraform" "$archiveDir\terraform" -Force
        Write-Success "Moved terraform/ to archive"
    }
    
    if (Test-Path "ansible") {
        Write-Step "Archiving ansible/"
        Move-Item "ansible" "$archiveDir\ansible" -Force
        Write-Success "Moved ansible/ to archive"
    }
    
    # Move old deployment script if exists
    if (Test-Path "deploy.ps1" -and (Test-Path "infrastructure\deploy.ps1")) {
        Write-Step "Archiving old deploy.ps1"
        Move-Item "deploy.ps1" "$archiveDir\deploy.ps1" -Force
        Write-Success "Moved old deploy.ps1 to archive"
    }
    
    Write-Success "Old structure archived to $archiveDir/"
}

# ===================================
# Main Execution
# ===================================

try {
    Write-Header "Destroy Old Infrastructure & Cleanup"
    
    switch ($Action) {
        "check" {
            $results = Invoke-Check
            
            Write-Host "`n💡 NEXT STEPS:`n" -ForegroundColor Cyan
            
            if ($results.HasResources) {
                Write-Host "1. Destroy AWS resources:" -ForegroundColor White
                Write-Host "   .\destroy-old.ps1 -Action destroy`n" -ForegroundColor Yellow
            }
            
            if ($results.HasFiles) {
                Write-Host "2. Archive old files:" -ForegroundColor White
                Write-Host "   .\destroy-old.ps1 -Action cleanup`n" -ForegroundColor Yellow
            }
            
            Write-Host "Or run everything:" -ForegroundColor White
            Write-Host "   .\destroy-old.ps1 -Action all`n" -ForegroundColor Yellow
        }
        
        "destroy" {
            Invoke-Destroy
        }
        
        "cleanup" {
            Invoke-Cleanup
        }
        
        "all" {
            Write-Host "This will:" -ForegroundColor Yellow
            Write-Host "  1. Destroy all AWS resources" -ForegroundColor White
            Write-Host "  2. Archive old structure files`n" -ForegroundColor White
            
            if (-not $Force) {
                $confirm = Read-Host "Type 'YES I AM SURE' to confirm"
                if ($confirm -ne "YES I AM SURE") {
                    Write-Host "Cancelled." -ForegroundColor Yellow
                    return
                }
            }
            
            Invoke-Destroy
            Invoke-Cleanup
            
            Write-Header "COMPLETE - Old Infrastructure Removed"
            
            Write-Host "✅ AWS resources destroyed" -ForegroundColor Green
            Write-Host "✅ Old files archived`n" -ForegroundColor Green
            
            Write-Host "Your project now has ONLY the new structure:" -ForegroundColor Cyan
            Write-Host "  • infrastructure/ - Professional modular infrastructure" -ForegroundColor White
            Write-Host "  • Jenkinsfile, k8s/ - Working application" -ForegroundColor White
            Write-Host "  • archive_old_structure_*/ - Backup of old files`n" -ForegroundColor White
        }
    }
    
} catch {
    Write-Host "`n❌ Operation failed: $_`n" -ForegroundColor Red
    exit 1
}
