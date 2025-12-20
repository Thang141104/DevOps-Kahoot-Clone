# Output values
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

# Ansible Inventory Output
output "ansible_inventory" {
  description = "Ansible inventory file content"
  value = templatefile("${path.module}/ansible-inventory.tpl", {
    jenkins_ip = aws_instance.jenkins_server.public_ip
    k8s_master_ip = aws_instance.k8s_master.public_ip
    k8s_worker_ips = aws_instance.k8s_workers[*].public_ip
  })
}

# Jenkins Outputs
output "jenkins_public_ip" {
  description = "Jenkins server public IP"
  value       = aws_instance.jenkins_server.public_ip
}

output "jenkins_url" {
  description = "Jenkins Web UI URL"
  value       = "http://${aws_instance.jenkins_server.public_ip}:8080"
}

output "jenkins_ssh_command" {
  description = "SSH command to connect to Jenkins"
  value       = "ssh -i jenkins-key.pem ubuntu@${aws_instance.jenkins_server.public_ip}"
}

# Kubernetes Cluster Outputs
output "k8s_master_ip" {
  description = "Kubernetes master node public IP"
  value       = aws_instance.k8s_master.public_ip
}

output "k8s_worker_ips" {
  description = "Kubernetes worker nodes public IPs"
  value       = aws_instance.k8s_workers[*].public_ip
}

output "k8s_ssh_commands" {
  description = "SSH commands for K8s nodes"
  value = {
    master = "ssh -i jenkins-key.pem ubuntu@${aws_instance.k8s_master.public_ip}"
    workers = [for ip in aws_instance.k8s_workers[*].public_ip : "ssh -i jenkins-key.pem ubuntu@${ip}"]
  }
}

# App Server Outputs - DISABLED (Using Kubernetes instead)
# output "security_group_id" {
#   description = "Security group ID"
#   value       = aws_security_group.app_server.id
# }

# output "instance_id" {
#   description = "EC2 instance ID"
#   value       = aws_instance.app_server.id
# }

# output "instance_public_ip" {
#   description = "EC2 instance public IP"
#   value       = var.use_elastic_ip ? aws_eip.app_server[0].public_ip : aws_instance.app_server.public_ip
# }

# output "instance_public_dns" {
#   description = "EC2 instance public DNS"
#   value       = aws_instance.app_server.public_dns
# }

# output "elastic_ip" {
#   description = "Elastic IP address (if enabled)"
#   value       = var.use_elastic_ip ? aws_eip.app_server[0].public_ip : "Not using Elastic IP"
# }

# output "frontend_url" {
#   description = "Frontend application URL"
#   value       = "http://${var.use_elastic_ip ? aws_eip.app_server[0].public_ip : aws_instance.app_server.public_ip}:3006"
# }

# output "api_gateway_url" {
#   description = "API Gateway URL"
#   value       = "http://${var.use_elastic_ip ? aws_eip.app_server[0].public_ip : aws_instance.app_server.public_ip}:3000"
# }

# output "ssh_connection" {
#   description = "SSH connection command"
#   value       = var.key_name != "" ? "ssh -i ${var.key_name}.pem ubuntu@${var.use_elastic_ip ? aws_eip.app_server[0].public_ip : aws_instance.app_server.public_ip}" : "No SSH key configured"
# }

# Kubernetes Cluster Outputs
output "k8s_master_public_ip" {
  description = "Public IP of the Kubernetes master node"
  value       = aws_eip.k8s_master.public_ip
}

output "k8s_master_private_ip" {
  description = "Private IP of the Kubernetes master node"
  value       = aws_instance.k8s_master.private_ip
}

output "k8s_workers_private_ips" {
  description = "Private IPs of the Kubernetes worker nodes"
  value       = aws_instance.k8s_workers[*].private_ip
}

output "k8s_master_ssh_command" {
  description = "SSH command to connect to the master node"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.k8s_master.public_ip}"
}

output "application_urls" {
  description = "URLs to access the application"
  value = {
    frontend   = "http://${aws_eip.k8s_master.public_ip}:30006"
    gateway    = "http://${aws_eip.k8s_master.public_ip}:30000"
    prometheus = "http://${aws_eip.k8s_master.public_ip}:30090"
    grafana    = "http://${aws_eip.k8s_master.public_ip}:30300"
  }
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    region          = var.aws_region
    instance_type   = var.instance_type
    ami_id          = data.aws_ami.ubuntu.id
    environment     = var.environment
  }
}

# Jenkins Outputs
output "jenkins_public_ip" {
  description = "Jenkins server public IP"
  value       = var.use_elastic_ip ? aws_eip.jenkins_eip[0].public_ip : aws_instance.jenkins_server.public_ip
}

output "jenkins_url" {
  description = "Jenkins Web UI URL"
  value       = "http://${var.use_elastic_ip ? aws_eip.jenkins_eip[0].public_ip : aws_instance.jenkins_server.public_ip}:8080"
}

output "jenkins_ssh_command" {
  description = "SSH command to connect to Jenkins server"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${var.use_elastic_ip ? aws_eip.jenkins_eip[0].public_ip : aws_instance.jenkins_server.public_ip}"
}

# Complete Infrastructure Summary
output "infrastructure_summary" {
  description = "Complete infrastructure summary"
  value = {
    jenkins = {
      public_ip   = var.use_elastic_ip ? aws_eip.jenkins_eip[0].public_ip : aws_instance.jenkins_server.public_ip
      web_ui      = "http://${var.use_elastic_ip ? aws_eip.jenkins_eip[0].public_ip : aws_instance.jenkins_server.public_ip}:8080"
      ssh_command = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${var.use_elastic_ip ? aws_eip.jenkins_eip[0].public_ip : aws_instance.jenkins_server.public_ip}"
    }
    k8s_cluster = {
      master_public_ip  = aws_eip.k8s_master.public_ip
      master_private_ip = aws_instance.k8s_master.private_ip
      worker_count      = var.worker_count
      workers_private_ips = aws_instance.k8s_workers[*].private_ip
      ssh_command       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.k8s_master.public_ip}"
    }
    ecr = {
      registry_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
      repositories = {
        for k, v in aws_ecr_repository.kahoot_services : k => v.repository_url
      }
    }
    application_urls = {
      frontend   = "http://${aws_eip.k8s_master.public_ip}:30006"
      gateway    = "http://${aws_eip.k8s_master.public_ip}:30000"
      prometheus = "http://${aws_eip.k8s_master.public_ip}:30090"
      grafana    = "http://${aws_eip.k8s_master.public_ip}:30300"
    }
  }
}
