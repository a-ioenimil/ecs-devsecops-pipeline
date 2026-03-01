# ==========================================
# VPC Outputs
# ==========================================
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

# ==========================================
# ALB Outputs
# ==========================================
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = module.alb.security_group_id
}

# ==========================================
# Security Group Outputs
# ==========================================
output "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

# ==========================================
# Target Group Outputs
# ==========================================
output "blue_target_group_arn" {
  description = "ARN of the Blue target group"
  value       = module.alb.target_groups["blue"].arn
}

output "green_target_group_arn" {
  description = "ARN of the Green target group"
  value       = module.alb.target_groups["green"].arn
}

output "blue_target_group_name" {
  description = "Name of the Blue target group"
  value       = module.alb.target_groups["blue"].name
}

output "green_target_group_name" {
  description = "Name of the Green target group"
  value       = module.alb.target_groups["green"].name
}

# ==========================================
# Listener Outputs
# ==========================================
output "prod_listener_arn" {
  description = "ARN of the production listener"
  value       = module.alb.listeners["prod"].arn
}

output "test_listener_arn" {
  description = "ARN of the test listener"
  value       = module.alb.listeners["test"].arn
}
