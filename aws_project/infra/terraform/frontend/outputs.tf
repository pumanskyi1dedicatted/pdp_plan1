output "frontend_bucket_id" {
  value       = aws_s3_bucket.front_s3.id
  description = "S3 bucket name for frontend files"
}

output "frontend_bucket_arn" {
  value       = aws_s3_bucket.front_s3.arn
  description = "S3 bucket ARN"
}

output "distribution_id" {
  value       = aws_cloudfront_distribution.s3_distribution.id
  description = "CloudFront distribution ID (used for cache invalidation)"
}

output "distribution_domain" {
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
  description = "CloudFront domain name to open the site"
}
