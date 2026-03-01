# ==========================================
# CODEDEPLOY APPLICATION
# ==========================================
resource "aws_codedeploy_app" "this" {
  compute_platform = "ECS"
  name             = "${var.app_name}-deploy-app"
}

# ==========================================
# CODEDEPLOY DEPLOYMENT GROUP (Blue/Green)
# ==========================================
resource "aws_codedeploy_deployment_group" "this" {
  app_name               = aws_codedeploy_app.this.name
  deployment_group_name  = "${var.app_name}-deploy-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce" # Use ECSLinear10PercentEvery1Minutes for safer rollouts
  service_role_arn       = var.codedeploy_role_arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.prod_listener_arn]
      }
      test_traffic_route {
        listener_arns = [var.test_listener_arn]
      }

      target_group {
        name = var.blue_target_group_name
      }

      target_group {
        name = var.green_target_group_name
      }
    }
  }
}

# ==========================================
# CODEPIPELINE ARTIFACT BUCKET
# ==========================================
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = var.codepipeline_bucket_name

  tags = { Name = "${var.app_name}-codepipeline-artifacts" }
}

# ==========================================
# CODEPIPELINE
# Listens on the deploy manifests repo and triggers CodeDeploy
# ==========================================
resource "aws_codepipeline" "this" {
  name     = "${var.app_name}-deploy-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit" # Or CodeStarSourceConnection for GitHub
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = var.deploy_manifests_repo_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_app.this.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.this.deployment_group_name
        TaskDefinitionTemplateArtifact = "source_output"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "source_output"
        AppSpecTemplatePath            = "appspec.yaml"
      }
    }
  }
}
