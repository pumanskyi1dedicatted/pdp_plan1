data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "fresh-project-pavel-terraform-state-2026"
    key    = "network/terraform.tfstate"
    region = "eu-north-1"
  }
}

data "terraform_remote_state" "database" {
  backend = "s3"
  config = {
    bucket = "fresh-project-pavel-terraform-state-2026"
    key    = "database/terraform.tfstate"
    region = "eu-north-1"
  }
}

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    bucket = "fresh-project-pavel-terraform-state-2026"
    key    = "ecr/terraform.tfstate"
    region = "eu-north-1"
  }
}

data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    bucket = "fresh-project-pavel-terraform-state-2026"
    key    = "dns/terraform.tfstate"
    region = "eu-north-1"
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

data "terraform_remote_state" "alerts" {
  backend = "s3"
  config = {
    bucket = "fresh-project-pavel-terraform-state-2026"
    key    = "alerts/terraform.tfstate"
    region = "eu-north-1"
  }
}

