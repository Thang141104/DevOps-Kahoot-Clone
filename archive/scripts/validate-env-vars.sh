#!/bin/bash
# Validation script to ensure environment variables are identical
# between Docker Compose and Kubernetes deployments

set -e

echo "🔍 Validating Environment Variables Consistency..."
echo "=================================================="

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to extract env vars from .env files
check_docker_compose_envs() {
    echo -e "\n📦 Docker Compose Environment Variables:"
    echo "----------------------------------------"
    
    services=("gateway" "auth-service" "quiz-service" "game-service" "user-service" "analytics-service" "frontend")
    
    for service in "${services[@]}"; do
        if [ "$service" = "frontend" ]; then
            env_file="frontend/.env"
        elif [ "$service" = "gateway" ]; then
            env_file="gateway/.env"
        else
            env_file="services/${service}/.env"
        fi
        
        echo "  $service:"
        if [ -f "$env_file" ]; then
            cat "$env_file" | grep -v '^#' | grep -v '^$' | sed 's/^/    /'
        else
            echo -e "    ${RED}✗ File not found${NC}"
        fi
        echo ""
    done
}

# Function to check K8s ConfigMap and Secrets
check_kubernetes_envs() {
    echo -e "\n☸️  Kubernetes Environment Variables:"
    echo "----------------------------------------"
    
    echo "  ConfigMap (app-config):"
    if [ -f "k8s/configmap.yaml" ]; then
        grep -A 50 "^data:" k8s/configmap.yaml | grep -v "^data:" | sed 's/^/    /'
    else
        echo -e "    ${RED}✗ configmap.yaml not found${NC}"
    fi
    
    echo ""
    echo "  Secrets (app-secrets):"
    if [ -f "k8s/secrets.yaml" ]; then
        grep -A 20 "^stringData:" k8s/secrets.yaml | grep -v "^stringData:" | grep -v "^  #" | sed 's/: .*/: ***REDACTED***/' | sed 's/^/    /'
    else
        echo -e "    ${RED}✗ secrets.yaml not found${NC}"
    fi
}

# Function to validate critical variables
validate_critical_vars() {
    echo -e "\n✅ Critical Variables Validation:"
    echo "----------------------------------------"
    
    critical_vars=("MONGODB_URI" "JWT_SECRET" "EMAIL_USER" "EMAIL_PASSWORD" "NODE_ENV")
    
    for var in "${critical_vars[@]}"; do
        # Check in K8s secrets
        k8s_has_var=$(grep -c "^  ${var}:" k8s/secrets.yaml 2>/dev/null || echo "0")
        
        # Check in Docker Compose .env files
        dc_has_var=$(find . -name ".env" -type f -exec grep -l "^${var}=" {} \; 2>/dev/null | wc -l)
        
        if [ "$k8s_has_var" -gt 0 ] && [ "$dc_has_var" -gt 0 ]; then
            echo -e "  ${GREEN}✓${NC} $var: Present in both K8s and Docker Compose"
        elif [ "$k8s_has_var" -gt 0 ]; then
            echo -e "  ${RED}✗${NC} $var: Only in K8s (missing from Docker Compose)"
        elif [ "$dc_has_var" -gt 0 ]; then
            echo -e "  ${RED}✗${NC} $var: Only in Docker Compose (missing from K8s)"
        else
            echo -e "  ${RED}✗${NC} $var: MISSING from both!"
        fi
    done
}

# Main execution
check_docker_compose_envs
check_kubernetes_envs
validate_critical_vars

echo ""
echo "=================================================="
echo "✅ Validation complete!"
echo ""
echo "💡 Tips:"
echo "  - Ensure k8s/secrets.yaml is auto-generated from Terraform"
echo "  - Never commit secrets.yaml to Git"
echo "  - Use secrets.yaml.example as template"
