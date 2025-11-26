#!/bin/bash
# Script to install Trivy inside Jenkins container
# Run this on the Jenkins EC2 instance

echo "Installing Trivy in Jenkins container..."

docker exec -u root jenkins bash -c "
  apt-get update && \
  apt-get install -y wget apt-transport-https gnupg lsb-release && \
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - && \
  echo 'deb https://aquasecurity.github.io/trivy-repo/deb \$(lsb_release -sc) main' | tee -a /etc/apt/sources.list.d/trivy.list && \
  apt-get update && \
  apt-get install -y trivy
"

echo "Verifying Trivy installation..."
docker exec jenkins trivy --version

echo "✅ Trivy installation completed successfully!"
