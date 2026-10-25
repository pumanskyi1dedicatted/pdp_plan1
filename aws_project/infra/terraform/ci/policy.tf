locals {
  account = data.aws_caller_identity.current.account_id

  cluster_arn         = "arn:aws:ecs:${var.region}:${local.account}:cluster/bankapi"
  service_arn         = "arn:aws:ecs:${var.region}:${local.account}:service/bankapi/bankapi"
  task_def_arns       = "arn:aws:ecs:${var.region}:${local.account}:task-definition/bankapi:*"
  tasks_arns          = "arn:aws:ecs:${var.region}:${local.account}:task/bankapi/*"
  task_execution_role = "arn:aws:iam::${local.account}:role/bankapi-task-execution"
  task_role           = "arn:aws:iam::${local.account}:role/bankapi-task"

  ecr_repo_arn     = data.terraform_remote_state.ecr.outputs.repository_arn
  site_bucket_arn  = data.terraform_remote_state.frontend.outputs.frontend_bucket_arn
  distribution_arn = "arn:aws:cloudfront::${local.account}:distribution/${data.terraform_remote_state.frontend.outputs.distribution_id}"
}

data "aws_iam_policy_document" "github_deploy" {
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "EcrPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
    ]
    resources = [local.ecr_repo_arn]
  }

  statement {
    sid = "EcsTaskDefinitions"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "EcsRunMigration"
    actions   = ["ecs:RunTask"]
    resources = [local.task_def_arns]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [local.cluster_arn]
    }
  }

  statement {
    sid       = "EcsDescribeTasks"
    actions   = ["ecs:DescribeTasks"]
    resources = [local.tasks_arns]
  }

  statement {
    sid = "EcsDeployService"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
    ]
    resources = [local.service_arn]
  }

  statement {
    sid       = "PassTaskRoles"
    actions   = ["iam:PassRole"]
    resources = [local.task_execution_role, local.task_role]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid       = "SiteBucketList"
    actions   = ["s3:ListBucket"]
    resources = [local.site_bucket_arn]
  }

  statement {
    sid = "SiteBucketObjects"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${local.site_bucket_arn}/*"]
  }

  statement {
    sid = "CloudFrontInvalidation"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
    ]
    resources = [local.distribution_arn]
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  name   = "deploy"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy.json
}
