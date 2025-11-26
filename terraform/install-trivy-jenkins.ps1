# Install Trivy in Jenkins Container - PowerShell Script
# Run this script to install Trivy on the running Jenkins instance

$JENKINS_IP = "3.217.0.239"
$SSH_KEY = "D:\DevOps_Lab2\DevOps-Kahoot-Clone\terraform\jenkins-key.pem"  # Update this path to your SSH key

Write-Host "Installing Trivy in Jenkins container on $JENKINS_IP..." -ForegroundColor Cyan

# Install Trivy inside Jenkins container via SSH
$installCommand = @"
docker exec -u root jenkins bash -c '
  apt-get update && \
  apt-get install -y wget apt-transport-https gnupg lsb-release && \
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - && \
  echo \"deb https://aquasecurity.github.io/trivy-repo/deb \`$(lsb_release -sc) main\" | tee -a /etc/apt/sources.list.d/trivy.list && \
  apt-get update && \
  apt-get install -y trivy
'
"@

Write-Host "`nExecuting installation command..." -ForegroundColor Yellow
ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@$JENKINS_IP $installCommand

Write-Host "`nVerifying Trivy installation..." -ForegroundColor Yellow
ssh -i $SSH_KEY ubuntu@$JENKINS_IP "docker exec jenkins trivy --version"

Write-Host "`n✅ Trivy installation completed successfully!" -ForegroundColor Green
Write-Host "`nYou can now run the Jenkins pipeline again." -ForegroundColor Cyan
