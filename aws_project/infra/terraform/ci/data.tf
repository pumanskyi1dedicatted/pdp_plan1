data "aws_iam_policy_document" "github_trust" {
  statement {
    sid     = "GitHubActionsOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]


    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }


    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }


    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    bucket = "fresh-project-pavel-terraform-state-2026"
    key    = "ecr/terraform.tfstate"
    region = "eu-north-1"
  }
}

data "terraform_remote_state" "frontend" {
  backend = "s3"
  config = {
    bucket = "fresh-project-pavel-terraform-state-2026"
    key    = "frontend/terraform.tfstate"
    region = "eu-north-1"
  }
}
