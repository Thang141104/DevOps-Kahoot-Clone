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
  description = "EC2 instance type"
  type        = string
  default     = "t3.small" 
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

# Jenkins Configuration
variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins server"
  type        = string
  default     = "t3.small"  # 2 vCPU, 2GB RAM (~$15/month)
}

# Kubernetes Configuration
variable "k8s_instance_type" {
  description = "EC2 instance type for Kubernetes master"
  type        = string
  default     = "t3.small"  # 2 vCPU, 2GB RAM (~$15/month)
}

