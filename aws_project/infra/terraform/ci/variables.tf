variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the role (owner/repo)"
  type        = string
}
