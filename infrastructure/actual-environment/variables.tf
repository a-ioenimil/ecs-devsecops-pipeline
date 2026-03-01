variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "eu-west-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for Terraform state"
}

variable "app_name" {
  type        = string
  description = "Application name used across all modules for resource naming"
  default     = "fastapi-app"
}

variable "container_port" {
  type        = number
  description = "Port the FastAPI container listens on"
  default     = 8000
}

variable "codepipeline_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for CodePipeline artifacts"
}

variable "deploy_manifests_repo_name" {
  type        = string
  description = "CodeCommit/GitHub full repository ID containing the deployment manifests (e.g., username/repo or org/repo)"
}
