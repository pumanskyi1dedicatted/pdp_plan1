variable "region" {
  description = "AWS region for frontend"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "Fresh Deploy"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "shared"
}

variable "alert_email" {
  description = "alert email"
  type        = string
}


