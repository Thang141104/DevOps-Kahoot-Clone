#!/bin/bash
# Script to generate Kubernetes secrets from Terraform variables
# This ensures environment variables are identical between Docker Compose and Kubernetes

set -e

# Source terraform variables
MONGODB_URI="${mongodb_uri}"
JWT_SECRET="${jwt_secret}"
EMAIL_USER="${email_user}"
EMAIL_PASSWORD="${email_password}"

# Generate k8s secrets.yaml
cat > /home/ubuntu/app/k8s/secrets.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: kahoot-clone
type: Opaque
stringData:
  # MongoDB Connection - Auto-generated from Terraform
  MONGODB_URI: "${MONGODB_URI}"
  
  # JWT Secret - Auto-generated from Terraform
  JWT_SECRET: "${JWT_SECRET}"
  
  # Email Configuration - Auto-generated from Terraform
  EMAIL_USER: "${EMAIL_USER}"
  EMAIL_PASSWORD: "${EMAIL_PASSWORD}"
  
  # Email Server Settings
  EMAIL_HOST: "smtp.gmail.com"
  EMAIL_PORT: "587"
  
  # Session Secret
  SESSION_SECRET: "${JWT_SECRET}"
  
  # OTP Settings
  OTP_EXPIRES_IN: "10"
EOF

# Generate k8s configmap.yaml with complete environment variables
cat > /home/ubuntu/app/k8s/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: kahoot-clone
data:
  NODE_ENV: "production"
  
  # Gateway
  GATEWAY_PORT: "3000"
  
  # Service URLs (internal Kubernetes service names)
  AUTH_SERVICE_URL: "http://auth-service:3001"
  QUIZ_SERVICE_URL: "http://quiz-service:3002"
  GAME_SERVICE_URL: "http://game-service:3003"
  USER_SERVICE_URL: "http://user-service:3004"
  ANALYTICS_SERVICE_URL: "http://analytics-service:3005"
  
  # Service Ports
  AUTH_PORT: "3001"
  QUIZ_PORT: "3002"
  GAME_PORT: "3003"
  USER_PORT: "3004"
  ANALYTICS_PORT: "3005"
  FRONTEND_PORT: "3006"
  
  # CORS
  CORS_ORIGIN: "*"
  
  # Email Server (non-sensitive)
  EMAIL_HOST: "smtp.gmail.com"
  EMAIL_PORT: "587"
  
  # OTP
  OTP_EXPIRES_IN: "10"
EOF

echo "✅ Kubernetes secrets and configmap generated successfully from Terraform variables"
echo "Files created:"
echo "  - /home/ubuntu/app/k8s/secrets.yaml"
echo "  - /home/ubuntu/app/k8s/configmap.yaml"
