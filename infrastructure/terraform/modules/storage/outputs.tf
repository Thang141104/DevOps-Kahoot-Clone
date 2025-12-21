output "avatar_bucket_name" {
  description = "Name of the S3 bucket for user avatars"
  value       = aws_s3_bucket.user_avatars.id
}

output "avatar_bucket_arn" {
  description = "ARN of the S3 bucket for user avatars"
  value       = aws_s3_bucket.user_avatars.arn
}

output "avatar_bucket_domain_name" {
  description = "Domain name of the S3 bucket for user avatars"
  value       = aws_s3_bucket.user_avatars.bucket_domain_name
}
