# ==========================================
# MODULE: IAM
# All IAM roles (ECS Exec, ECS Task, CodeDeploy, CodePipeline)
# ==========================================
module "iam" {
  source   = "./modules/iam"
  app_name = var.app_name
}

# ==========================================
# MODULE: ECR
# Container registry with lifecycle policy
# ==========================================
module "ecr" {
  source   = "./modules/ecr"
  app_name = var.app_name
}

# ==========================================
# MODULE: NETWORKING
# VPC, ALB, Listeners (Prod/Test), Target Groups (Blue/Green), ECS SG
# ==========================================
module "networking" {
  source         = "./modules/networking"
  app_name       = var.app_name
  container_port = var.container_port
}

# ==========================================
# MODULE: ECS
# Cluster, Task Definition, Service (CODE_DEPLOY controller)
# ==========================================
module "ecs" {
  source = "./modules/ecs"

  app_name              = var.app_name
  aws_region            = var.aws_region
  ecr_repository_url    = module.ecr.repository_url
  execution_role_arn    = module.iam.ecs_task_execution_role_arn
  task_role_arn         = module.iam.ecs_task_role_arn
  container_port        = var.container_port
  private_subnets       = module.networking.private_subnets
  ecs_security_group_id = module.networking.ecs_tasks_security_group_id
  blue_target_group_arn = module.networking.blue_target_group_arn
  assign_public_ip      = false # Private subnets with NAT Gateway
}

# ==========================================
# MODULE: CI/CD
# CodeDeploy (Blue/Green) + CodePipeline
# ==========================================
module "cicd" {
  source = "./modules/cicd"

  app_name                   = var.app_name
  codedeploy_role_arn        = module.iam.codedeploy_role_arn
  codepipeline_role_arn      = module.iam.codepipeline_role_arn
  ecs_cluster_name           = module.ecs.cluster_name
  ecs_service_name           = module.ecs.service_name
  prod_listener_arn          = module.networking.prod_listener_arn
  test_listener_arn          = module.networking.test_listener_arn
  blue_target_group_name     = module.networking.blue_target_group_name
  green_target_group_name    = module.networking.green_target_group_name
  codepipeline_bucket_name   = var.codepipeline_bucket_name
  deploy_manifests_repo_name = var.deploy_manifests_repo_name
}
