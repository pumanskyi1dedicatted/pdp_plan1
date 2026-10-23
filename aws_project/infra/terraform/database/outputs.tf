output "db_address" {
  value       = aws_db_instance.fresh-deploy-rds.address
  description = "RDS address"
}

output "db_port" {
  value       = aws_db_instance.fresh-deploy-rds.port
  description = "RDS opened port"
}

output "db_name" {
  value       = aws_db_instance.fresh-deploy-rds.db_name
  description = "DB name"
}

output "db_secret_arn" {
  value       = aws_db_instance.fresh-deploy-rds.master_user_secret[0].secret_arn
  description = "ARN of the Secrets Manager secret with the master user credentials"
}

output "db_security_group_id" {
  value       = aws_security_group.rds_security_group.id
  description = "DB security group id"
}



