#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/k8s-master-setup.log|logger -t k8s-master -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Kubernetes Master Node Setup"
echo "=========================================="

# Update system
echo "=== Updating system packages ==="
apt-get update -y
apt-get upgrade -y

# Disable swap (required for Kubernetes)
echo "=== Disabling swap ==="
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Configure kernel modules
echo "=== Configuring kernel modules ==="
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Configure sysctl
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Install containerd
echo "=== Installing containerd ==="
apt-get install -y containerd

# Configure containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# Install Kubernetes components
echo "=== Installing kubeadm, kubelet, kubectl ==="
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Enable kubelet
systemctl enable kubelet

# Get node IP
PRIVATE_IP=$(hostname -I | awk '{print $1}')

# Initialize Kubernetes cluster
echo "=== Initializing Kubernetes cluster ==="
kubeadm init \
  --pod-network-cidr=${pod_network_cidr} \
  --apiserver-advertise-address=$PRIVATE_IP \
  --control-plane-endpoint=$PRIVATE_IP \
  --upload-certs

# Setup kubeconfig for ubuntu user
echo "=== Setting up kubeconfig ==="
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Setup kubeconfig for root
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config

# Install Calico CNI
echo "=== Installing Calico CNI ==="
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

# Wait for operator to be ready
sleep 30

# Install Calico custom resources
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml

# Install Helm
echo "=== Installing Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Docker (for building images)
echo "=== Installing Docker ==="
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# Create namespaces
echo "=== Creating namespaces ==="
sleep 30  # Wait for cluster to be fully ready
kubectl --kubeconfig=/etc/kubernetes/admin.conf create namespace kahoot-clone
kubectl --kubeconfig=/etc/kubernetes/admin.conf create namespace monitoring

# Clone repository
echo "=== Setting up application ==="
mkdir -p /home/ubuntu/app
cd /home/ubuntu/app
git clone -b ${github_branch} ${github_repo} .
chown -R ubuntu:ubuntu /home/ubuntu/app

# Get public IP for API configuration
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Build frontend with runtime API URL
echo "=== Building frontend with API URL: http://$PUBLIC_IP:30000 ==="
docker build -t 22521284/kahoot-clone-frontend:latest ./frontend

# Generate Kubernetes secrets
echo "=== Generating Kubernetes secrets ==="
cat > /home/ubuntu/app/k8s/secrets.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: kahoot-clone
type: Opaque
stringData:
  # MongoDB - Use provided URI or fallback to in-cluster MongoDB
  MONGODB_URI: "${mongodb_uri}"
  JWT_SECRET: "${jwt_secret}"
  EMAIL_USER: "${email_user}"
  EMAIL_PASSWORD: "${email_password}"
  EMAIL_HOST: "smtp.gmail.com"
  EMAIL_PORT: "587"
  SESSION_SECRET: "${jwt_secret}"
  OTP_EXPIRES_IN: "10"
EOF

# Generate ConfigMap with service URLs
echo "=== Generating ConfigMap ==="
cat > /home/ubuntu/app/k8s/configmap.yaml << EOF
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
  
  # JWT
  JWT_EXPIRES_IN: "7d"
  
  # Email Server (non-sensitive)
  EMAIL_HOST: "smtp.gmail.com"
  EMAIL_PORT: "587"
  
  # OTP
  OTP_EXPIRES_IN: "10"
EOF

# Update frontend deployment with correct API URL
echo "=== Updating frontend deployment with Public IP ==="
sed -i "s|value: \"http://gateway:3000\"|value: \"http://$PUBLIC_IP:30000\"|g" /home/ubuntu/app/k8s/frontend-deployment.yaml

# Save join command for workers
echo "=== Generating worker join command ==="
kubeadm token create --print-join-command > /home/ubuntu/join-command.sh
chmod +x /home/ubuntu/join-command.sh

# Make join command accessible via HTTP (for workers to fetch)
apt-get install -y nginx
cat > /var/www/html/join-command.sh << EOF
$(cat /home/ubuntu/join-command.sh)
EOF
chmod 644 /var/www/html/join-command.sh

# Deploy application (will be done manually or via CI/CD)
echo "=== Cluster setup complete ==="
echo "Master node ready. Workers will join automatically."
echo ""
echo "To deploy the application manually:"
echo "  kubectl apply -f k8s/"
echo ""
echo "Public IP: $PUBLIC_IP"
echo "Access cluster: export KUBECONFIG=/home/ubuntu/.kube/config"
