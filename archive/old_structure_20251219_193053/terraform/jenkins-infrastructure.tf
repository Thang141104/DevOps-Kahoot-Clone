# Jenkins Infrastructure

resource "aws_security_group" "jenkins_sg" {
  name        = "${var.environment}-jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Jenkins
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins Web UI"
  }

  # Jenkins Agent
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins Agent"
  }

  # Docker Registry
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Docker Registry"
  }

  # Kubernetes API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes API"
  }

  # NodePort range for K8s services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes NodePort range"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-jenkins-sg"
    Environment = var.environment
    Service     = "Jenkins"
  }
}

resource "aws_instance" "jenkins_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.jenkins_instance_type
  key_name      = var.key_name
  
  # Attach IAM role for ECR access
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name
  
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = aws_subnet.public.id
  
  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  user_data = templatefile("${path.module}/jenkins-user-data.sh", {
    aws_region     = var.aws_region
    github_repo    = var.github_repo
    github_branch  = var.github_branch
    mongodb_uri    = var.mongodb_uri
    email_user     = var.email_user
    email_password = var.email_password
    jwt_secret     = var.jwt_secret
  })

  tags = {
    Name        = "${var.environment}-jenkins-server"
    Environment = var.environment
    Service     = "Jenkins"
  }
}

resource "aws_eip" "jenkins_eip" {
  count    = var.use_elastic_ip ? 1 : 0
  instance = aws_instance.jenkins_server.id
  domain   = "vpc"

  tags = {
    Name        = "${var.environment}-jenkins-eip"
    Environment = var.environment
  }
}

# OLD: Single-node k3s cluster (DISABLED - Use k8s-cluster.tf instead for 3-node cluster)
# Uncomment this section if you want Jenkins + single k3s node instead of 3-node cluster
# 
# resource "aws_instance" "k8s_single_node" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = var.k8s_instance_type
#   key_name      = var.key_name
#   
#   vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
#   subnet_id              = aws_subnet.public.id
#   
#   root_block_device {
#     volume_size = 30
#     volume_type = "gp2"
#   }
#
#   user_data = templatefile("${path.module}/user-data.sh", {
#     github_repo    = var.github_repo
#     github_branch  = var.github_branch
#     mongodb_uri    = var.mongodb_uri
#     email_user     = var.email_user
#     email_password = var.email_password
#     jwt_secret     = var.jwt_secret
#   })
#
#   tags = {
#     Name        = "${var.environment}-k8s-single-node"
#     Environment = var.environment
#     Service     = "Kubernetes"
#   }
# }
#
# resource "aws_eip" "k8s_single_eip" {
#   count    = var.use_elastic_ip ? 1 : 0
#   instance = aws_instance.k8s_single_node.id
#   domain   = "vpc"
#
#   tags = {
#     Name        = "${var.environment}-k8s-single-eip"
#     Environment = var.environment
#   }
# }

output "jenkins_public_ip" {
  value       = var.use_elastic_ip ? aws_eip.jenkins_eip[0].public_ip : aws_instance.jenkins_server.public_ip
  description = "Public IP of Jenkins server"
}

output "jenkins_url" {
  value       = "http://${var.use_elastic_ip ? aws_eip.jenkins_eip[0].public_ip : aws_instance.jenkins_server.public_ip}:8080"
  description = "Jenkins Web UI URL"
}

# OLD outputs - disabled
# output "k8s_single_node_ip" {
#   value       = var.use_elastic_ip ? aws_eip.k8s_single_eip[0].public_ip : aws_instance.k8s_single_node.public_ip
#   description = "Public IP of single-node Kubernetes cluster"
# }
#
# output "k8s_api_endpoint" {
#   value       = "https://${var.use_elastic_ip ? aws_eip.k8s_single_eip[0].public_ip : aws_instance.k8s_single_node.public_ip}:6443"
#   description = "Kubernetes API endpoint"
# }
