output "alb_dns_name" {
  value       = aws_lb.api.dns_name
  description = "ALB address for the CloudFront origin"
}

output "origin_header_name" {
  value = local.origin_header_name
}

output "origin_secret" {
  value     = random_password.origin_secret.result
  sensitive = true
}

output "origin_domain" {
  value = local.origin_domain
}
