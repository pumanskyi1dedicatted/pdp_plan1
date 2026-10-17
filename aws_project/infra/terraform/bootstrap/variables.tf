# bootstrap/variables.tf
variable "region" {
  description = "AWS region for state bucket"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Terraform state bucket name (globally unique)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "shared"
}
