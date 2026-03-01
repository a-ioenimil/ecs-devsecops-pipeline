variable "app_name" {
  type        = string
  description = "Application name used for resource naming"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where resources will be deployed"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet IDs for the ALB"
}

variable "container_port" {
  type        = number
  description = "The port the container listens on"
  default     = 8000
}
