# Output values
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
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

output "deployment_info" {
  description = "Deployment information"
  value = {
    region          = var.aws_region
    instance_type   = var.instance_type
    ami_id          = data.aws_ami.ubuntu.id
    environment     = var.environment
  }
}
