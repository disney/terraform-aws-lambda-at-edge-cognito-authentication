# ================================================================================================================
# Enhanced Monitoring and Observability for Lambda@Edge
# ================================================================================================================

# CloudWatch Log Group for Lambda@Edge (automatically created by AWS)
# Note: Lambda@Edge logs are automatically replicated to CloudWatch Logs in each edge location

# Optional: Custom CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "lambda_edge_dashboard" {
  count          = var.enable_enhanced_monitoring ? 1 : 0
  dashboard_name = "${var.name}-lambda-edge-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.cloudfront_auth_edge.function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Lambda@Edge Metrics"
          period  = 300
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Purpose = "Lambda@Edge Monitoring"
    Module  = "terraform-aws-lambda-at-edge-cognito-authentication"
  })
}

# CloudWatch Alarms for Lambda@Edge
resource "aws_cloudwatch_metric_alarm" "lambda_error_rate" {
  count               = var.enable_enhanced_monitoring ? 1 : 0
  alarm_name          = "${var.name}-lambda-edge-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_rate_threshold
  alarm_description   = "This metric monitors lambda error rate"

  dimensions = {
    FunctionName = aws_lambda_function.cloudfront_auth_edge.function_name
  }

  tags = merge(var.tags, {
    Purpose = "Lambda@Edge Error Monitoring"
    Module  = "terraform-aws-lambda-at-edge-cognito-authentication"
  })
