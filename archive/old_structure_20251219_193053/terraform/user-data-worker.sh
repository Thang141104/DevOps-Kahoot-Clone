#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/k8s-worker-setup.log|logger -t k8s-worker -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Kubernetes Worker Node Setup"
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

# Wait for master node to be ready and fetch join command
echo "=== Waiting for master node (${master_private_ip}) ==="
MASTER_IP="${master_private_ip}"
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES: Checking if master is ready..."
    
    # Try to fetch join command from master's nginx
    if curl -f -s http://$MASTER_IP/join-command.sh -o /tmp/join-command.sh; then
        echo "Successfully fetched join command from master!"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo "ERROR: Failed to fetch join command after $MAX_RETRIES attempts"
        echo "Master node may not be ready yet. Manual join required."
        exit 1
    fi
    
    echo "Master not ready yet. Waiting 30 seconds..."
    sleep 30
done

# Join the cluster
echo "=== Joining Kubernetes cluster ==="
chmod +x /tmp/join-command.sh
bash /tmp/join-command.sh

echo "=== Worker node setup complete ==="
echo "Node has joined the cluster successfully!"
