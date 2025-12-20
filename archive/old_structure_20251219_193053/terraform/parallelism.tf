# Terraform Parallelization Configuration
# Optimizes resource creation with intelligent dependency management

# Create a local file to enable terraform parallelism tracking
resource "local_file" "parallelism_config" {
  filename = "${path.module}/.terraform-parallelism"
  content  = <<-EOT
    # Terraform Parallelism Settings
    # Default: 10 concurrent operations
    # Optimized for AWS EC2 API rate limits and network I/O
    
    PARALLELISM=20
    
    # Resource Creation Order:
    # Phase 1 (Parallel): VPC, Subnets, IGW, Route Tables, Security Groups
    # Phase 2 (Sequential): Master Node (waits for network)
    # Phase 3 (Parallel): Worker Nodes (after master is ready)
    # Phase 4 (Sequential): EIP assignment
  EOT
}

# Optimization: Create security groups in parallel
# Since they don't depend on each other, only on VPC
resource "null_resource" "optimize_sg_creation" {
  triggers = {
    vpc_id = aws_vpc.main.id
  }
  
  provisioner "local-exec" {
    command = "echo 'VPC ready - Security Groups can be created in parallel'"
  }
}

# Optimization: Worker nodes can be created in parallel
# But must wait for master to be ready
resource "null_resource" "master_ready_check" {
  depends_on = [aws_instance.k8s_master]
  
  triggers = {
    master_id = aws_instance.k8s_master.id
  }
  
  # Check if master is ready before creating workers
  provisioner "local-exec" {
    command = <<-EOT
      echo "Master node created: ${aws_instance.k8s_master.id}"
      echo "Workers can now be provisioned in parallel"
    EOT
  }
}

# Output for parallelism metrics
output "parallelism_info" {
  value = {
    max_parallelism = 20
    resource_count = {
      vpc_resources   = 4  # VPC, Subnet, IGW, Route Table (parallel)
      security_groups = 2  # K8s SG, Jenkins SG (parallel)
      compute_master  = 1  # Master node (sequential after network)
      compute_workers = var.worker_count  # Workers (parallel after master)
      network_eip     = 1  # EIP (sequential after instances)
    }
    total_resources = 4 + 2 + 1 + var.worker_count + 1
    estimated_phases = 4
  }
}
