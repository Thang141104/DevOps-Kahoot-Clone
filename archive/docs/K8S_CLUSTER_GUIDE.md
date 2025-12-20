# Kubernetes 3-Node Cluster Deployment Guide

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    AWS VPC (10.0.0.0/16)                │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │           Public Subnet (10.0.1.0/24)             │ │
│  │                                                   │ │
│  │  ┌──────────────────┐                            │ │
│  │  │  Master Node     │                            │ │
│  │  │  - API Server    │                            │ │
│  │  │  - Scheduler     │                            │ │
│  │  │  - Controller    │                            │ │
│  │  │  - etcd          │                            │ │
│  │  │  t3.medium       │                            │ │
│  │  └────────┬─────────┘                            │ │
│  │           │                                       │ │
│  │           │ Pod Network (192.168.0.0/16)         │ │
│  │           │ Calico CNI                           │ │
│  │           │                                       │ │
│  │  ┌────────┴─────────┬──────────────────┐        │ │
│  │  │                  │                  │        │ │
│  │  ▼                  ▼                  ▼        │ │
│  │  ┌──────────┐  ┌──────────┐                    │ │
│  │  │ Worker-1 │  │ Worker-2 │                    │ │
│  │  │ t3.medium│  │ t3.medium│                    │ │
│  │  │          │  │          │                    │ │
│  │  │ Pods:    │  │ Pods:    │                    │ │
│  │  │ - auth   │  │ - quiz   │                    │ │
│  │  │ - user   │  │ - game   │                    │ │
│  │  │ - gateway│  │ - analytics                  │ │
│  │  │ - frontend│ │ - mongodb│                   │ │
│  │  └──────────┘  └──────────┘                    │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## 📋 Infrastructure Details

### Node Specifications

| Node | Instance Type | vCPUs | RAM | Storage | Role |
|------|--------------|-------|-----|---------|------|
| Master | t3.medium | 2 | 4GB | 30GB | Control Plane |
| Worker-1 | t3.medium | 2 | 4GB | 30GB | Application Workloads |
| Worker-2 | t3.medium | 2 | 4GB | 30GB | Application Workloads |

### Kubernetes Version
- **Kubernetes**: v1.28.x
- **Container Runtime**: containerd
- **CNI**: Calico v3.26.1
- **Orchestration Tool**: kubeadm

### Network Configuration
- **Pod Network CIDR**: 192.168.0.0/16 (Calico)
- **Service CIDR**: 10.96.0.0/12 (default)
- **VPC CIDR**: 10.0.0.0/16
- **Public Subnet**: 10.0.1.0/24

## 🚀 Deployment Steps

### 1. Configure Terraform Variables

Edit `terraform/terraform.tfvars`:

```hcl
# AWS Credentials
aws_access_key = "YOUR_ACCESS_KEY"
aws_secret_key = "YOUR_SECRET_KEY"
aws_region     = "us-east-1"

# SSH Key
key_name = "your-key-name"  # Must exist in AWS

# Cluster Configuration
master_instance_type = "t3.medium"
worker_instance_type = "t3.medium"
worker_count         = 2

# Pod Network
pod_network_cidr = "192.168.0.0/16"

# Application Secrets
mongodb_uri    = "mongodb://mongodb:27017"
jwt_secret     = "your-jwt-secret"
email_user     = "your-email@gmail.com"
email_password = "your-app-password"

# GitHub Repository
github_repo   = "https://github.com/yourusername/DevOps-Kahoot-Clone"
github_branch = "main"

# Project Name
project_name = "kahoot-clone"
```

### 2. Initialize and Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Deploy infrastructure (creates 3 EC2 instances)
terraform apply -auto-approve
```

**Expected Output:**
```
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:
k8s_master_public_ip = "54.88.12.253"
k8s_master_private_ip = "10.0.1.100"
k8s_workers_private_ips = [
  "10.0.1.101",
  "10.0.1.102"
]
k8s_master_ssh_command = "ssh -i ~/.ssh/your-key.pem ubuntu@54.88.12.253"
application_urls = {
  frontend   = "http://54.88.12.253:30006"
  gateway    = "http://54.88.12.253:30000"
  prometheus = "http://54.88.12.253:30090"
  grafana    = "http://54.88.12.253:30300"
}
```

### 3. Wait for Cluster Initialization

The automated setup takes approximately **10-15 minutes**:

1. **Master Node** (5-7 minutes):
   - Install containerd, kubeadm, kubelet
   - Initialize Kubernetes cluster
   - Install Calico CNI
   - Generate join token
   - Serve join command via nginx

2. **Worker Nodes** (8-12 minutes):
   - Install containerd, kubeadm, kubelet
   - Fetch join command from master
   - Join cluster automatically

**Monitor Progress:**
```bash
# SSH to master node
ssh -i ~/.ssh/your-key.pem ubuntu@<MASTER_PUBLIC_IP>

# Watch setup logs
tail -f /var/log/k8s-master-setup.log

# Check if master is ready
kubectl get nodes
```

### 4. Verify Cluster Status

```bash
# SSH to master
ssh -i ~/.ssh/your-key.pem ubuntu@<MASTER_PUBLIC_IP>

# Check all nodes
kubectl get nodes

# Expected output:
# NAME                          STATUS   ROLES           AGE   VERSION
# ip-10-0-1-100.ec2.internal    Ready    control-plane   10m   v1.28.x
# ip-10-0-1-101.ec2.internal    Ready    <none>          8m    v1.28.x
# ip-10-0-1-102.ec2.internal    Ready    <none>          8m    v1.28.x

# Check system pods
kubectl get pods -A

# Expected output:
# NAMESPACE     NAME                                       READY   STATUS    RESTARTS
# kube-system   calico-kube-controllers-xxx                1/1     Running   0
# kube-system   calico-node-xxx                            1/1     Running   0
# kube-system   calico-node-yyy                            1/1     Running   0
# kube-system   calico-node-zzz                            1/1     Running   0
# kube-system   coredns-xxx                                1/1     Running   0
# kube-system   coredns-yyy                                1/1     Running   0
# kube-system   etcd-ip-10-0-1-100                         1/1     Running   0
# kube-system   kube-apiserver-ip-10-0-1-100               1/1     Running   0
# kube-system   kube-controller-manager-ip-10-0-1-100      1/1     Running   0
# kube-system   kube-scheduler-ip-10-0-1-100               1/1     Running   0
```

### 5. Deploy Application

```bash
# On master node
cd /home/ubuntu/app

# Apply secrets and configmap
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml

# Deploy all services
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/

# Wait for pods to be ready
kubectl get pods -n kahoot-clone -w
```

**Expected Pods:**
```
NAME                                READY   STATUS    RESTARTS   AGE
auth-service-xxx                    1/1     Running   0          2m
user-service-xxx                    1/1     Running   0          2m
quiz-service-xxx                    1/1     Running   0          2m
game-service-xxx                    1/1     Running   0          2m
analytics-service-xxx               1/1     Running   0          2m
gateway-xxx                         1/1     Running   0          2m
frontend-xxx                        1/1     Running   0          2m
mongodb-xxx                         1/1     Running   0          2m
```

## 🔍 Verification & Testing

### Check Node Distribution

```bash
# See which node each pod is running on
kubectl get pods -n kahoot-clone -o wide

# Expected distribution across 2 workers:
# NAME                     NODE
# auth-service-xxx         ip-10-0-1-101.ec2.internal
# user-service-xxx         ip-10-0-1-102.ec2.internal
# quiz-service-xxx         ip-10-0-1-101.ec2.internal
# game-service-xxx         ip-10-0-1-102.ec2.internal
# ...
```

### Test Application

```bash
# Get master public IP
MASTER_IP=$(terraform output -raw k8s_master_public_ip)

# Test frontend
curl http://$MASTER_IP:30006

# Test gateway API
curl http://$MASTER_IP:30000/api/health

# Test Prometheus
curl http://$MASTER_IP:30090

# Test Grafana
curl http://$MASTER_IP:30300
```

### Access Application URLs

Open in browser:
- **Frontend**: http://MASTER_IP:30006
- **Gateway API**: http://MASTER_IP:30000
- **Prometheus**: http://MASTER_IP:30090
- **Grafana**: http://MASTER_IP:30300

## 🛠️ Management Commands

### View Cluster Information

```bash
# Cluster info
kubectl cluster-info

# Node details
kubectl describe nodes

# Resource usage
kubectl top nodes  # Requires metrics-server

# All resources
kubectl get all -A
```

### Scale Deployments

```bash
# Scale manually
kubectl scale deployment frontend -n kahoot-clone --replicas=3

# Check pod distribution
kubectl get pods -n kahoot-clone -o wide
```

### Drain Node (for maintenance)

```bash
# Drain worker-1 (move pods to worker-2)
kubectl drain ip-10-0-1-101.ec2.internal --ignore-daemonsets

# Make node unschedulable
kubectl cordon ip-10-0-1-101.ec2.internal

# Re-enable scheduling
kubectl uncordon ip-10-0-1-101.ec2.internal
```

### Manual Worker Join (if automatic join fails)

```bash
# On master node
kubeadm token create --print-join-command

# Copy the output, then on worker node:
sudo <join-command-from-above>
```

## 🔧 Troubleshooting

### Worker Not Joining Cluster

```bash
# On worker node, check logs
tail -f /var/log/k8s-worker-setup.log

# Check if master is reachable
ping <MASTER_PRIVATE_IP>
curl http://<MASTER_PRIVATE_IP>/join-command.sh

# Manual join
ssh ubuntu@<MASTER_IP>
kubeadm token create --print-join-command
# Then run output on worker
```

### Pod Not Scheduling

```bash
# Check node status
kubectl get nodes

# Check pod events
kubectl describe pod <POD_NAME> -n kahoot-clone

# Check node resources
kubectl describe node <NODE_NAME>
```

### CNI Issues (Calico)

```bash
# Check Calico pods
kubectl get pods -n calico-system

# Calico node status
kubectl exec -n calico-system calico-node-xxx -- calico-node status

# Restart Calico
kubectl delete pod -n calico-system -l k8s-app=calico-node
```

### DNS Not Working

```bash
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test DNS from a pod
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns
```

## 📊 Monitoring

### Install Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check metrics
kubectl top nodes
kubectl top pods -n kahoot-clone
```

### Prometheus & Grafana (Already Deployed)

Access monitoring dashboards:
- **Prometheus**: http://MASTER_IP:30090
- **Grafana**: http://MASTER_IP:30300 (admin/admin)

## 🔐 Security Best Practices

### Network Policies

```bash
# Example: Restrict frontend to only access gateway
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
  namespace: kahoot-clone
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: gateway
EOF
```

### RBAC

```bash
# Create read-only user
kubectl create serviceaccount readonly-user -n kahoot-clone
kubectl create rolebinding readonly-binding \
  --clusterrole=view \
  --serviceaccount=kahoot-clone:readonly-user \
  -n kahoot-clone
```

## 💰 Cost Estimation

### Monthly AWS Costs

| Resource | Quantity | Unit Cost | Total |
|----------|----------|-----------|-------|
| t3.medium EC2 | 3 | $30.37/month | $91.11 |
| EBS gp3 (30GB) | 3 | $2.40/month | $7.20 |
| Elastic IP | 1 | $3.60/month | $3.60 |
| Data Transfer | ~50GB | $4.50 | $4.50 |
| **Total** | | | **~$106/month** |

**Cost Optimization:**
- Use Spot Instances: Save 70% (workers)
- Reserved Instances: Save 40% (1-year commitment)
- Stop instances during off-hours: Save 50%

## 🔄 Scaling the Cluster

### Add More Workers

Edit `terraform/terraform.tfvars`:
```hcl
worker_count = 3  # or 4, 5, etc.
```

Then:
```bash
terraform apply -auto-approve
```

New workers will automatically join the cluster.

### Upgrade Instance Types

Edit `terraform/terraform.tfvars`:
```hcl
master_instance_type = "t3.large"
worker_instance_type = "t3.large"
```

Then:
```bash
terraform apply -auto-approve
```

## 🗑️ Cleanup

### Destroy Infrastructure

```bash
cd terraform
terraform destroy -auto-approve
```

This will delete:
- All 3 EC2 instances
- Elastic IP
- Security groups
- VPC resources

**Total time**: ~2 minutes

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Calico Documentation](https://docs.tigera.io/calico/latest/about/)
- [kubeadm Setup Guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
