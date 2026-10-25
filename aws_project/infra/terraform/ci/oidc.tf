resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}


resource "aws_iam_role" "github_deploy" {
  name                 = "github-actions-deploy"
  description          = "Deploy from GitHub Actions (OIDC), main branch only"
  assume_role_policy   = data.aws_iam_policy_document.github_trust.json
  max_session_duration = 3600
}
