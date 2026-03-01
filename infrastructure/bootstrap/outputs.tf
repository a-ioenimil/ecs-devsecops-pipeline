output "s3_bucket_name" {
  description = "Name of the S3 bucket used for Terraform State"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform State"
  value       = aws_s3_bucket.terraform_state.arn
}
