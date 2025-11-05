# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app_server.id]
  key_name               = var.key_name != "" ? var.key_name : null

  # User data script to install Docker, clone repo, and run application
  user_data = templatefile("${path.module}/user-data.sh", {
    github_repo     = var.github_repo
    github_branch   = var.github_branch
    mongodb_uri     = var.mongodb_uri
    jwt_secret      = var.jwt_secret
    email_user      = var.email_user
    email_password  = var.email_password
  })

  # Root volume configuration
  root_block_device {
    volume_size           = 20 # GB
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = false

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  # Enable detailed monitoring (optional)
  monitoring = false

  tags = {
    Name = "${var.project_name}-app-server"
  }

  # Wait for instance to be ready before considering it created
  depends_on = [
    aws_internet_gateway.main
  ]
}

# Elastic IP (optional, for fixed public IP)
resource "aws_eip" "app_server" {
  count    = var.use_elastic_ip ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.app_server.id

  tags = {
    Name = "${var.project_name}-eip"
  }

  depends_on = [aws_internet_gateway.main]
}
