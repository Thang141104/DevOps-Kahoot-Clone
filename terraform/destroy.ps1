# Destroy script for Terraform
# This script helps you destroy the infrastructure safely

Write-Host "=== Kahoot Clone - Terraform Destroy Script ===" -ForegroundColor Red
Write-Host ""
Write-Host "⚠️  WARNING: This will DELETE all infrastructure!" -ForegroundColor Yellow
Write-Host ""

# Show current infrastructure
Write-Host "=== Current Infrastructure ===" -ForegroundColor Cyan
terraform show

Write-Host ""
Write-Host "=== Resources to be destroyed ===" -ForegroundColor Red
terraform plan -destroy

Write-Host ""
Write-Host "⚠️  This action is IRREVERSIBLE!" -ForegroundColor Red
Write-Host "⚠️  All data on the EC2 instance will be lost!" -ForegroundColor Red
Write-Host "⚠️  MongoDB Atlas data will NOT be deleted (managed separately)" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Are you ABSOLUTELY SURE you want to destroy? Type 'yes' to confirm"

if ($confirm -eq "yes") {
    $doubleConfirm = Read-Host "Type 'destroy' to proceed"
    
    if ($doubleConfirm -eq "destroy") {
        Write-Host ""
        Write-Host "=== Destroying Infrastructure ===" -ForegroundColor Red
        terraform destroy -auto-approve
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✓ Infrastructure destroyed successfully" -ForegroundColor Green
            Write-Host ""
            Write-Host "Cleaned up resources:" -ForegroundColor Cyan
            Write-Host "  ✓ EC2 Instance terminated" -ForegroundColor White
            Write-Host "  ✓ Elastic IP released" -ForegroundColor White
            Write-Host "  ✓ Security Group deleted" -ForegroundColor White
            Write-Host "  ✓ VPC and subnets deleted" -ForegroundColor White
            Write-Host ""
            Write-Host "Note: MongoDB Atlas data is preserved" -ForegroundColor Yellow
        } else {
            Write-Host "✗ Destroy failed!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Destroy cancelled - confirmation failed." -ForegroundColor Yellow
    }
} else {
    Write-Host "Destroy cancelled." -ForegroundColor Yellow
}
