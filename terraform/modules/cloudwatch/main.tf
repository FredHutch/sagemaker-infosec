# Log group for SageMaker
resource "aws_cloudwatch_log_group" "sagemaker" {
  name              = "/aws/sagemaker/${var.sagemaker_domain_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = {
    Name        = "SageMaker InfoSec Logs"
    Environment = var.environment
  }
}

# CloudWatch alarms for security monitoring
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "sagemaker-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/SageMaker"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors SageMaker CPU utilization"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    DomainId = var.sagemaker_domain_name
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "sagemaker-${var.environment}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/SageMaker"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors SageMaker memory utilization"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    DomainId = var.sagemaker_domain_name
  }
}

# Dashboard for security operations
resource "aws_cloudwatch_dashboard" "sagemaker_security" {
  dashboard_name = "SageMaker-InfoSec-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/SageMaker", "CPUUtilization", { stat = "Average" }],
            [".", "MemoryUtilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "SageMaker Resource Utilization"
        }
      },
      {
        type = "log"
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.sagemaker.name}' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = data.aws_region.current.name
          title   = "Recent SageMaker Logs"
        }
      }
    ]
  })
}

data "aws_region" "current" {}
