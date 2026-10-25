output "github_actions_role_arn" {
  value       = aws_iam_role.github_deploy.arn
  description = "Role ARN for aws-actions/configure-aws-credentials"
}
