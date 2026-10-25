data "terraform_remote_state" "backend" {
  backend = "s3"
  config = {
    bucket = "fresh-project-pavel-terraform-state-2026"
    key    = "backend/terraform.tfstate"
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

