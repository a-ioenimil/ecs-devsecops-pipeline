variable "app_name" {
  type        = string
  description = "Application name used for resource naming"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones for the subnets"
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the private subnets"
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "container_port" {
  type        = number
  description = "The port the container listens on"
  default     = 8000
}
