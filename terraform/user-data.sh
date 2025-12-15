#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/k8s-setup.log|logger -t k8s-setup -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting Kubernetes (k3s) Setup"
echo "=========================================="

# Update system
echo "=== Updating system packages ==="
apt-get update -y
apt-get upgrade -y

# Install required packages
echo "=== Installing required packages ==="
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    software-properties-common

# Install k3s (lightweight Kubernetes)
echo "=== Installing k3s ==="
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode=644" sh -

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
sleep 30

# Export kubeconfig
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Install Helm
echo "=== Installing Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Create namespaces
echo "=== Creating namespaces ==="
kubectl create namespace kahoot-clone
kubectl create namespace monitoring

# Create application directory
echo "=== Setting up application directory ==="
mkdir -p /home/ubuntu/app
cd /home/ubuntu/app

# Clone repository
echo "=== Cloning repository ==="
git clone -b ${github_branch} ${github_repo} .

# NOTE: Docker images are pre-built and pushed to Docker Hub
# Build them once using: docker build + docker push from local or Jenkins
# K8s will pull images from Docker Hub (no build needed here)

# Generate Kubernetes secrets from Terraform variables
echo "=== Generating Kubernetes secrets ==="
cat > /home/ubuntu/app/k8s/secrets.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: kahoot-clone
type: Opaque
stringData:
  MONGODB_URI: "${mongodb_uri}"
  JWT_SECRET: "${jwt_secret}"
  EMAIL_USER: "${email_user}"
  EMAIL_PASSWORD: "${email_password}"
  EMAIL_HOST: "smtp.gmail.com"
  EMAIL_PORT: "587"
  SESSION_SECRET: "${jwt_secret}"
  OTP_EXPIRES_IN: "10"
EOF

# Apply secrets to cluster
kubectl apply -f /home/ubuntu/app/k8s/secrets.yaml

# Deploy Prometheus
echo "=== Deploying Prometheus ==="
cat > /home/ubuntu/prometheus-deployment.yaml << 'PROM_EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    scrape_configs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
            namespaces:
              names:
                - kahoot-clone
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
            target_label: __address__

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      serviceAccountName: prometheus
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        args:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus'
          - '--web.console.libraries=/usr/share/prometheus/console_libraries'
          - '--web.console.templates=/usr/share/prometheus/consoles'
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
        - name: storage
          mountPath: /prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
      - name: storage
        emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  type: NodePort
  selector:
    app: prometheus
  ports:
    - protocol: TCP
      port: 9090
      targetPort: 9090
      nodePort: 30090

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
PROM_EOF

kubectl apply -f /home/ubuntu/prometheus-deployment.yaml

# Deploy Grafana
echo "=== Deploying Grafana ==="
cat > /home/ubuntu/grafana-deployment.yaml << 'GRAF_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: "admin"
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
      volumes:
      - name: grafana-storage
        emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
spec:
  type: NodePort
  selector:
    app: grafana
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
      nodePort: 30300
GRAF_EOF

kubectl apply -f /home/ubuntu/grafana-deployment.yaml

# Wait for monitoring pods to start
echo "=== Waiting for monitoring pods ==="
sleep 60

# Deploy application to K8s
echo "=== Deploying application to Kubernetes ==="
cd /home/ubuntu/app/k8s
kubectl apply -f namespace.yaml 2>/dev/null || true
kubectl apply -f configmap.yaml 2>/dev/null || true
kubectl apply -f secrets.yaml
kubectl apply -f auth-deployment.yaml 2>/dev/null || true
kubectl apply -f user-deployment.yaml 2>/dev/null || true
kubectl apply -f quiz-deployment.yaml 2>/dev/null || true
kubectl apply -f game-deployment.yaml 2>/dev/null || true
kubectl apply -f analytics-deployment.yaml 2>/dev/null || true
kubectl apply -f gateway-deployment.yaml 2>/dev/null || true
kubectl apply -f frontend-deployment.yaml 2>/dev/null || true

# Copy kubeconfig to ubuntu user
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# Create helper scripts
cat > /home/ubuntu/show-monitoring.sh << 'MONITORING'
#!/bin/bash
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "=========================================="
echo "Monitoring Stack URLs"
echo "=========================================="
echo "Prometheus: http://$PUBLIC_IP:30090"
echo "Grafana:    http://$PUBLIC_IP:30300"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "Monitoring Pods Status:"
kubectl get pods -n monitoring
echo ""
echo "Application Pods Status:"
kubectl get pods -n kahoot-clone
echo "=========================================="
MONITORING

chmod +x /home/ubuntu/show-monitoring.sh
chown ubuntu:ubuntu /home/ubuntu/show-monitoring.sh

# Display access information
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "=========================================="
echo "=== Kubernetes cluster ready! ==="
echo "=========================================="
echo "Prometheus: http://$PUBLIC_IP:30090"
echo "Grafana:    http://$PUBLIC_IP:30300 (admin/admin)"
echo ""
echo "Run: /home/ubuntu/show-monitoring.sh to see status"
echo "=========================================="

# Fix frontend API URL to use public IP (for browser access)
echo "=== Updating frontend API URL ==="
sleep 60  # Wait for frontend pods to be ready
kubectl set env deployment/frontend REACT_APP_API_URL=http://$PUBLIC_IP:30000 -n kahoot-clone
echo "Frontend API URL updated to: http://$PUBLIC_IP:30000"

# Show final status
kubectl get nodes
kubectl get pods -n monitoring
kubectl get pods -n kahoot-clone 2>/dev/null || true
