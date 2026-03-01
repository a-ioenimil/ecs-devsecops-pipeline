variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "eu-west-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique name for the S3 remote state bucket"
}
