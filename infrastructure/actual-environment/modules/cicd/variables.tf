variable "app_name" {
  type        = string
  description = "Application name"
}

variable "codedeploy_role_arn" {
  type        = string
  description = "ARN of the CodeDeploy service role"
}

variable "codepipeline_role_arn" {
  type        = string
  description = "ARN of the CodePipeline service role"
}

variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

variable "ecs_service_name" {
  type        = string
  description = "Name of the ECS service"
}

variable "prod_listener_arn" {
  type        = string
  description = "ARN of the production ALB listener"
}

variable "test_listener_arn" {
  type        = string
  description = "ARN of the test ALB listener"
}

variable "blue_target_group_name" {
  type        = string
  description = "Name of the Blue target group"
}

variable "green_target_group_name" {
  type        = string
  description = "Name of the Green target group"
}

variable "codepipeline_bucket_name" {
  type        = string
  description = "S3 bucket name for CodePipeline artifacts"
}

variable "deploy_manifests_repo_name" {
  type        = string
  description = "Name of the CodeCommit/GitHub repository containing deploy manifests"
}
