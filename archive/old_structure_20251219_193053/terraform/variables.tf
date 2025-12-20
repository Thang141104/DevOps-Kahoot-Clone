# AWS Credentials (Should be overridden in terraform.tfvars or environment variables)
variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

# AWS Region
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

# Environment
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type (deprecated - use master/worker specific)"
  type        = string
  default     = "t3.small" 
}

# Kubernetes Cluster Configuration
variable "master_instance_type" {
  description = "EC2 instance type for Kubernetes master node"
  type        = string
  default     = "c7i-flex.large"  # 2 vCPU, 4GB RAM - Free Tier eligible
}

variable "worker_instance_type" {
  description = "EC2 instance type for Kubernetes worker nodes"
  type        = string
  default     = "c7i-flex.large"  # 2 vCPU, 4GB RAM - Free Tier eligible
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "pod_network_cidr" {
  description = "CIDR block for pod network (Calico)"
  type        = string
  default     = "192.168.0.0/16"
}

variable "key_name" {
  description = "SSH Key pair name (must exist in AWS)"
  type        = string
  default     = "" 
}

# Application Configuration
variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/Thang141104/DevOps-Kahoot-Clone.git"
}

variable "github_branch" {
  description = "GitHub branch to clone"
  type        = string
  default     = "main"
}

# MongoDB Configuration
variable "mongodb_uri" {
  description = "MongoDB Atlas connection string"
  type        = string
  sensitive   = true
}

# Email Configuration (for OTP)
variable "email_user" {
  description = "Email address for sending OTP"
  type        = string
  default     = ""
}

variable "email_password" {
  description = "Email password for sending OTP"
  type        = string
  sensitive   = true
  default     = ""
}

# JWT Secret
variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
  default     = "your-super-secret-jwt-key-change-this-in-production"
}

# Elastic IP
variable "use_elastic_ip" {
  description = "Whether to use Elastic IP for fixed public IP"
  type        = bool
  default     = true
}

# Project Tags
variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "Kahoot-Clone"
}

# Jenkins Infrastructure Configuration
variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins server"
  type        = string
  default     = "t3.medium"
}

variable "k8s_instance_type" {
  description = "EC2 instance type for Kubernetes master node"
  type        = string
  default     = "t3.medium"
}

# Docker Hub Configuration (for building and pushing images)
variable "dockerhub_username" {
  description = "Docker Hub username for pushing images"
  type        = string
  default     = "22521284"
}

variable "dockerhub_password" {
  description = "Docker Hub password or access token"
  type        = string
  sensitive   = true
  default     = ""
}
