terraform {
  required_version = ">= 1.16.5"

  backend "s3" {
    bucket       = "fresh-project-pavel-terraform-state-2026"
    key          = "alerts/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.69.1"
    }
  }
}

