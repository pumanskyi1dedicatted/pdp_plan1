locals {
  cluster_name   = "bankapi"
  container_name = "bankapi"
  db             = data.terraform_remote_state.database.outputs

  private_subnet_ids = [
    data.terraform_remote_state.network.outputs.private_subnet_id_eu_north_1a,
    data.terraform_remote_state.network.outputs.private_subnet_id_eu_north_1b,
  ]
}

resource "aws_ecs_cluster" "main" {
  name = local.cluster_name
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/bankapi"
  retention_in_days = 7
}


resource "aws_launch_template" "ecs" {
  name_prefix            = "bankapi-ecs-"
  image_id               = data.aws_ssm_parameter.ecs_ami.insecure_value
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.ecs_instances.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance.arn
  }

  metadata_options {
    http_tokens = "required"
  }

  user_data = base64encode(<<-EOT
    #!/bin/bash
    echo "ECS_CLUSTER=${local.cluster_name}" >> /etc/ecs/ecs.config
    echo "ECS_AWSVPC_BLOCK_IMDS=true" >> /etc/ecs/ecs.config
  EOT
  )
}


resource "aws_autoscaling_group" "ecs" {
  name                = "bankapi-ecs"
  vpc_zone_identifier = local.private_subnet_ids
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "bankapi"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name         = local.container_name
    image        = "${data.terraform_remote_state.ecr.outputs.repository_url}:${var.image_tag}"
    essential    = true
    portMappings = [{ containerPort = 5000 }]

    environment = [
      { name = "DB_HOST", value = local.db.db_address },
      { name = "DB_PORT", value = tostring(local.db.db_port) },
      { name = "DB_NAME", value = local.db.db_name },
    ]

    secrets = [
      { name = "DB_USER", valueFrom = "${local.db.db_secret_arn}:username::" },
      { name = "DB_PASSWORD", valueFrom = "${local.db.db_secret_arn}:password::" },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.api.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "api"
      }
    }
  }])
}

resource "aws_ecs_service" "api" {
  name                   = "bankapi"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.api.arn
  desired_count          = 1
  launch_type            = "EC2"
  enable_execute_command = true

  network_configuration {
    subnets         = local.private_subnet_ids
    security_groups = [aws_security_group.api_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = local.container_name
    container_port   = 5000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener_rule.from_cloudfront]
}
