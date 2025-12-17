# ========================================
# Kubernetes Cluster - 3 Nodes Setup
# 1 Master + 2 Workers
# ========================================

# Master Node
resource "aws_instance" "k8s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.master_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s_cluster.id]
  key_name               = var.key_name != "" ? var.key_name : null

  # User data script for master node
  user_data = templatefile("${path.module}/user-data-master.sh", {
    github_repo    = var.github_repo
    github_branch  = var.github_branch
    mongodb_uri    = var.mongodb_uri
    jwt_secret     = var.jwt_secret
    email_user     = var.email_user
    email_password = var.email_password
    pod_network_cidr = var.pod_network_cidr
  })

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = false

    tags = {
      Name = "${var.project_name}-master-volume"
    }
  }

  monitoring = false

  tags = {
    Name = "${var.project_name}-k8s-master"
    Role = "master"
    Cluster = var.project_name
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}

# Worker Nodes
resource "aws_instance" "k8s_workers" {
  count                  = var.worker_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s_cluster.id]
  key_name               = var.key_name != "" ? var.key_name : null

  # User data script for worker nodes
  user_data = templatefile("${path.module}/user-data-worker.sh", {
    master_private_ip = aws_instance.k8s_master.private_ip
  })

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = false

    tags = {
      Name = "${var.project_name}-worker-${count.index + 1}-volume"
    }
  }

  monitoring = false

  tags = {
    Name = "${var.project_name}-k8s-worker-${count.index + 1}"
    Role = "worker"
    Cluster = var.project_name
  }

  depends_on = [
    aws_internet_gateway.main,
    aws_instance.k8s_master
  ]
}

# Elastic IP for Master Node (stable access)
resource "aws_eip" "k8s_master" {
  domain   = "vpc"
  instance = aws_instance.k8s_master.id

  tags = {
    Name = "${var.project_name}-master-eip"
  }

  depends_on = [aws_internet_gateway.main]
}
