locals {
  asg           = aws_autoscaling_group.ecs.name
  alb           = aws_lb.api.arn_suffix
  tg            = aws_lb_target_group.api.arn_suffix
  db_id         = data.terraform_remote_state.database.outputs.db_identifier
  alarm_actions = [data.terraform_remote_state.alerts.outputs.alerts_topic_arn]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "bankapi"
  dashboard_body = jsonencode({
    widgets = [
      { type = "metric", x = 0, y = 0, width = 8, height = 6, properties = {
        title = "EC2 CPU %", region = var.region, stat = "Average", period = 300,
      metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", local.asg]] } },
      { type = "metric", x = 8, y = 0, width = 8, height = 6, properties = {
        title = "EC2 RAM %", region = var.region, stat = "Average", period = 60,
      metrics = [["CWAgent", "mem_used_percent", "AutoScalingGroupName", local.asg]] } },
      { type = "metric", x = 16, y = 0, width = 8, height = 6, properties = {
        title = "EC2 network, bytes", region = var.region, stat = "Sum", period = 300,
        metrics = [
          ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", local.asg],
          ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", local.asg],
      ] } },

      # ALB
      { type = "metric", x = 0, y = 6, width = 8, height = 6, properties = {
        title = "ALB requests", region = var.region, stat = "Sum", period = 60,
      metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb]] } },
      { type = "metric", x = 8, y = 6, width = 8, height = 6, properties = {
        title = "5xx errors", region = var.region, stat = "Sum", period = 60,
        metrics = [
          ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb],
          ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", local.alb],
      ] } },
      { type = "metric", x = 16, y = 6, width = 8, height = 6, properties = {
        title = "Response time p95, s", region = var.region, stat = "p95", period = 60,
      metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb]] } },

      # ecs services health
      { type = "metric", x = 0, y = 12, width = 8, height = 6, properties = {
        title = "ECS service CPU / memory %", region = var.region, stat = "Average", period = 60,
        metrics = [
          ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.api.name],
          ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.api.name],
      ] } },
      { type = "metric", x = 8, y = 12, width = 8, height = 6, properties = {
        title = "Healthy targets", region = var.region, stat = "Minimum", period = 60,
      metrics = [["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", local.tg, "LoadBalancer", local.alb]] } },
      { type = "metric", x = 16, y = 12, width = 8, height = 6, properties = {
        title = "EC2 disk used %", region = var.region, stat = "Average", period = 60,
      metrics = [["CWAgent", "disk_used_percent", "AutoScalingGroupName", local.asg]] } },

      # RDS
      { type = "metric", x = 0, y = 18, width = 8, height = 6, properties = {
        title = "RDS CPU %", region = var.region, stat = "Average", period = 300,
      metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", local.db_id]] } },
      { type = "metric", x = 8, y = 18, width = 8, height = 6, properties = {
        title = "RDS connections", region = var.region, stat = "Maximum", period = 60,
      metrics = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", local.db_id]] } },
      { type = "metric", x = 16, y = 18, width = 8, height = 6, properties = {
        title = "RDS free memory / storage, bytes", region = var.region, stat = "Minimum", period = 300,
        metrics = [
          ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", local.db_id],
          ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", local.db_id],
      ] } },
    ]
  })
}

# alerts
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "bankapi-ec2-cpu-high"
  alarm_description   = "ECS instance CPU above 80% for 10 minutes"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { AutoScalingGroupName = local.asg }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "ec2_memory_high" {
  alarm_name          = "bankapi-ec2-memory-high"
  alarm_description   = "ECS instance RAM above 85% for 5 minutes"
  namespace           = "CWAgent"
  metric_name         = "mem_used_percent"
  dimensions          = { AutoScalingGroupName = local.asg }
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 85
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "bankapi-5xx"
  alarm_description   = "More than 5 server errors from the API in 5 minutes"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  dimensions          = { LoadBalancer = local.alb }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "no_healthy_targets" {
  alarm_name          = "bankapi-no-healthy-targets"
  alarm_description   = "No healthy API tasks behind the ALB for 3 minutes"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  dimensions          = { TargetGroup = local.tg, LoadBalancer = local.alb }
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "bankapi-rds-cpu-high"
  alarm_description   = "RDS CPU above 80% for 10 minutes"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBInstanceIdentifier = local.db_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "bankapi-rds-storage-low"
  alarm_description   = "RDS free storage below 2 GB"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  dimensions          = { DBInstanceIdentifier = local.db_id }
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2147483648
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
}
