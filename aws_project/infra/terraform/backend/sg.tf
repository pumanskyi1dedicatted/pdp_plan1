locals {
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
}


resource "aws_security_group" "alb" {
  name        = "bankapi-alb"
  description = "ALB: HTTP from CloudFront only"
  vpc_id      = local.vpc_id

  tags = {
    Name = "bankapi-alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" {
  security_group_id = aws_security_group.alb.id
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from CloudFront"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_tasks" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.api_tasks.id
  ip_protocol                  = "tcp"
  from_port                    = 5000
  to_port                      = 5000
  description                  = "To API tasks"
}

resource "aws_security_group" "api_tasks" {
  name        = "bankapi-tasks"
  description = "API tasks: traffic from ALB, connections to the database"
  vpc_id      = local.vpc_id

  tags = {
    Name = "bankapi-tasks"
  }
}

resource "aws_vpc_security_group_ingress_rule" "tasks_from_alb" {
  security_group_id            = aws_security_group.api_tasks.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 5000
  to_port                      = 5000
  description                  = "From ALB"
}

resource "aws_vpc_security_group_egress_rule" "tasks_to_db" {
  security_group_id            = aws_security_group.api_tasks.id
  referenced_security_group_id = data.terraform_remote_state.database.outputs.db_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "To PostgreSQL"
}

resource "aws_security_group" "ecs_instances" {
  name        = "bankapi-ecs-instances"
  description = "ECS instances: no inbound, HTTPS outbound for ECS, ECR, logs, secrets, SSM"
  vpc_id      = local.vpc_id

  tags = {
    Name = "bankapi-ecs-instances"
  }
}

resource "aws_vpc_security_group_egress_rule" "instances_https_out" {
  security_group_id = aws_security_group.ecs_instances.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS to AWS services"
}

resource "aws_vpc_security_group_ingress_rule" "db_from_tasks" {
  security_group_id            = data.terraform_remote_state.database.outputs.db_security_group_id
  referenced_security_group_id = aws_security_group.api_tasks.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL from API tasks"
}
