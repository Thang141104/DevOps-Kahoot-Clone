# ============================================
# GCP Variables Configuration
# ============================================

# GCP Project Configuration
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

# Environment
variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

# Project Configuration
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "kahoot-clone"
}

# Networking Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Application Configuration
variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/Thang141104/DevOps-Kahoot-Clone.git"
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "main"
}

# Database Configuration
variable "mongodb_uri" {
  description = "MongoDB connection string (Atlas or Cloud SQL)"
  type        = string
  sensitive   = true
}

variable "enable_cloud_sql" {
  description = "Enable Cloud SQL for PostgreSQL (alternative to MongoDB)"
  type        = bool
  default     = false
}

# Email Configuration
variable "email_user" {
  description = "Email address for sending notifications"
  type        = string
  default     = ""
}

variable "email_password" {
  description = "Email password"
  type        = string
  sensitive   = true
  default     = ""
}

# JWT Configuration
variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
  default     = "your-super-secret-jwt-key-change-this-in-production"
}

# Cloud Run Configuration
variable "cloud_run_min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
  default     = 0
}

variable "cloud_run_max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 10
}

variable "cloud_run_cpu" {
  description = "CPU allocation for Cloud Run"
  type        = string
  default     = "1"
}

variable "cloud_run_memory" {
  description = "Memory allocation for Cloud Run"
  type        = string
  default     = "512Mi"
}

# GKE Configuration (if using Kubernetes)
variable "enable_gke" {
  description = "Enable GKE cluster"
  type        = bool
  default     = false
}

variable "gke_node_count" {
  description = "Number of GKE nodes"
  type        = number
  default     = 3
}

variable "gke_machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "e2-standard-2"
}

# Compute Engine Configuration (for Jenkins)
variable "enable_jenkins_vm" {
  description = "Enable Compute Engine VM for Jenkins"
  type        = bool
  default     = false
}

variable "jenkins_machine_type" {
  description = "Jenkins VM machine type"
  type        = string
  default     = "e2-medium"
}

# BigQuery Configuration
variable "enable_bigquery" {
  description = "Enable BigQuery for analytics"
  type        = bool
  default     = true
}

variable "bigquery_dataset_location" {
  description = "BigQuery dataset location"
  type        = string
  default     = "US"
}

# Dataproc Configuration
variable "enable_dataproc" {
  description = "Enable Dataproc cluster"
  type        = bool
  default     = false
}

variable "dataproc_num_workers" {
  description = "Number of Dataproc worker nodes"
  type        = number
  default     = 2
}

variable "dataproc_worker_machine_type" {
  description = "Dataproc worker machine type"
  type        = string
  default     = "n1-standard-2"
}

# Cloud Storage Configuration
variable "storage_class" {
  description = "Storage class for Cloud Storage buckets"
  type        = string
  default     = "STANDARD"
}

variable "storage_location" {
  description = "Location for Cloud Storage buckets"
  type        = string
  default     = "US"
}

# Monitoring Configuration
variable "enable_cloud_monitoring" {
  description = "Enable Cloud Monitoring and Logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

# Deployment Method
variable "deployment_method" {
  description = "Deployment method: cloud-run, gke, or hybrid"
  type        = string
  default     = "cloud-run"
  
  validation {
    condition     = contains(["cloud-run", "gke", "hybrid"], var.deployment_method)
    error_message = "Deployment method must be cloud-run, gke, or hybrid."
  }
}
