# ==========================================
# ECR Outputs
# ==========================================
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

# ==========================================
# Networking Outputs
# ==========================================
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.networking.alb_dns_name
}

# ==========================================
# ECS Outputs
# ==========================================
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

# ==========================================
# CI/CD Outputs
# ==========================================
output "codedeploy_app_name" {
  description = "CodeDeploy Application Name"
  value       = module.cicd.codedeploy_app_name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy Deployment Group Name"
  value       = module.cicd.codedeploy_deployment_group_name
}

output "codepipeline_name" {
  description = "CodePipeline Name"
  value       = module.cicd.codepipeline_name
}
