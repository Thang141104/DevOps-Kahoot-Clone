# Storage Module Main Configuration
# Includes S3 bucket for user avatars

# Get AWS account ID
data "aws_caller_identity" "current" {}
