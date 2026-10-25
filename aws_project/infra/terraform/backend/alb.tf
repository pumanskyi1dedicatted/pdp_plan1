resource "random_password" "origin_secret" {
  length  = 32
  special = false
}

locals {
  origin_header_name = "X-Origin-Verify"
}

resource "aws_lb" "api" {
  name               = "bankapi-alb"
  internal           = false
  load_balancer_type = "application"
  subnets = [
    data.terraform_remote_state.network.outputs.public_subnet_id_eu_north_1a,
    data.terraform_remote_state.network.outputs.public_subnet_id_eu_north_1b,
  ]
  security_groups            = [aws_security_group.alb.id]
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "api" {
  name                 = "bankapi-tg"
  port                 = 5000
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = data.terraform_remote_state.network.outputs.vpc_id
  deregistration_delay = 30

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
  }
}


resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.api.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.terraform_remote_state.dns.outputs.alb_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "from_cloudfront" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    http_header {
      http_header_name = local.origin_header_name
      values           = [random_password.origin_secret.result]
    }
  }
}
