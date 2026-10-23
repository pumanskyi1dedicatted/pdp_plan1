data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "fresh-project-pavel-terraform-state-2026"
    key    = "network/terraform.tfstate"
    region = "eu-north-1"
  }
}
