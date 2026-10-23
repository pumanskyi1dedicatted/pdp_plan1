output "repository_url" {
  value       = aws_ecr_repository.bankapi.repository_url
  description = "Repository URL for docker push and the ECS task definition"
}

output "repository_arn" {
  value       = aws_ecr_repository.bankapi.arn
  description = "Repository ARN for IAM policies (CI push, ECS pull)"
}

output "repository_name" {
  value       = aws_ecr_repository.bankapi.name
  description = "Repository name"
}
