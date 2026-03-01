variable "app_name" {
  type        = string
  description = "Application name"
}

variable "aws_region" {
  type        = string
  description = "AWS region for CloudWatch logs"
}

variable "ecr_repository_url" {
  type        = string
  description = "ECR repository URL for the container image"
}

variable "execution_role_arn" {
  type        = string
  description = "ARN of the ECS Task Execution Role"
}

variable "task_role_arn" {
  type        = string
  description = "ARN of the ECS Task Role"
}

variable "container_port" {
  type        = number
  description = "The port the container listens on"
  default     = 8000
}

variable "task_cpu" {
  type        = number
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Memory (MiB) for the task"
  default     = 512
}

variable "desired_count" {
  type        = number
  description = "Number of desired ECS tasks"
  default     = 2
}

variable "private_subnets" {
  type        = list(string)
  description = "Subnet IDs for ECS tasks"
}

variable "ecs_security_group_id" {
  type        = string
  description = "Security group ID for ECS tasks"
}

variable "blue_target_group_arn" {
  type        = string
  description = "ARN of the blue target group for the initial load balancer attachment"
}

variable "assign_public_ip" {
  type        = bool
  description = "Whether to assign a public IP to ECS tasks. Set to false if using private subnets with NAT Gateway."
  default     = true
}
