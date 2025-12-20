# ================================
# IAM Roles for ECR Access
# ================================

# IAM Role for Jenkins to push/pull from ECR
resource "aws_iam_role" "jenkins_ecr_role" {
  name = "${var.project_name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-jenkins-role"
    Project = var.project_name
  }
}

# IAM Policy for Jenkins ECR access
resource "aws_iam_role_policy" "jenkins_ecr_policy" {
  name = "${var.project_name}-jenkins-ecr-policy"
  role = aws_iam_role.jenkins_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile for Jenkins EC2
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${var.project_name}-jenkins-profile"
  role = aws_iam_role.jenkins_ecr_role.name
}

# IAM Role for K8s nodes to pull from ECR
resource "aws_iam_role" "k8s_node_ecr_role" {
  name = "${var.project_name}-k8s-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-k8s-node-role"
    Project = var.project_name
  }
}

# IAM Policy for K8s nodes ECR pull access
resource "aws_iam_role_policy" "k8s_node_ecr_policy" {
  name = "${var.project_name}-k8s-node-ecr-policy"
  role = aws_iam_role.k8s_node_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeImages"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile for K8s nodes
resource "aws_iam_instance_profile" "k8s_node_profile" {
  name = "${var.project_name}-k8s-node-profile"
  role = aws_iam_role.k8s_node_ecr_role.name
}
