resource "aws_ssm_parameter" "cw_agent" {
  name = "AmazonCloudWatch-bankapi"
  type = "String"
  value = jsonencode({
    agent = { metrics_collection_interval = 60 }
    metrics = {
      namespace = "CWAgent"
      append_dimensions = {
        AutoScalingGroupName = "$${aws:AutoScalingGroupName}"
        InstanceId           = "$${aws:InstanceId}"
      }
      aggregation_dimensions = [["AutoScalingGroupName"]]
      metrics_collected = {
        mem  = { measurement = ["mem_used_percent"] }
        disk = { measurement = ["used_percent"], resources = ["/"], drop_device = true }
      }
    }
  })
}
