output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS Task Execution Role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS Task Role"
  value       = aws_iam_role.ecs_task.arn
}

output "codedeploy_role_arn" {
  description = "ARN of the CodeDeploy Service Role"
  value       = aws_iam_role.codedeploy.arn
}

output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline Service Role"
  value       = aws_iam_role.codepipeline.arn
}
