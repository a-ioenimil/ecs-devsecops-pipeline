output "codedeploy_app_name" {
  description = "The CodeDeploy Application Name"
  value       = aws_codedeploy_app.this.name
}

output "codedeploy_deployment_group_name" {
  description = "The CodeDeploy Deployment Group Name"
  value       = aws_codedeploy_deployment_group.this.deployment_group_name
}

output "codepipeline_name" {
  description = "The CodePipeline Name"
  value       = aws_codepipeline.this.name
}
