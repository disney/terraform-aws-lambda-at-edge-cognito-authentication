output "arn" {
  description = "ARN for the Lambda@Edge created by this module."
  value       = aws_lambda_function.cloudfront_auth_edge.arn
}

output "qualified_arn" {
  description = "Qualified ARN for the Lambda@Edge created by this module."
  value       = aws_lambda_function.cloudfront_auth_edge.qualified_arn
}

output "function_name" {
  description = "Name of the Lambda@Edge created by this module."
  value       = aws_lambda_function.cloudfront_auth_edge.function_name
}

# ================================================================================================================
# Security Enhancement Outputs
# ================================================================================================================

output "secrets_manager_arn" {
  description = "ARN of the Secrets Manager secret (if enabled)."
  value       = var.use_secrets_manager ? aws_secretsmanager_secret.lambda_secrets[0].arn : null
}

output "enhanced_kms_key_arn" {
  description = "ARN of the enhanced KMS key for SSM parameters."
  value       = local.create_ssm_parameter ? aws_kms_key.enhanced_ssm_kms_key[0].arn : null
}

output "enhanced_kms_key_id" {
  description = "ID of the enhanced KMS key for SSM parameters."
  value       = local.create_ssm_parameter ? aws_kms_key.enhanced_ssm_kms_key[0].key_id : null
}

output "security_group_id" {
  description = "ID of the Lambda security group (if VPC config is enabled)."
  value       = var.enable_vpc_config ? aws_security_group.lambda_security_group[0].id : null
}

output "audit_trail_arn" {
  description = "ARN of the CloudTrail audit trail (if enabled)."
  value       = var.enable_audit_logging ? aws_cloudtrail.lambda_audit_trail[0].arn : null
}

output "audit_s3_bucket" {
  description = "Name of the S3 bucket for audit logs (if enabled)."
  value       = var.enable_audit_logging ? aws_s3_bucket.audit_logs[0].id : null
}

# ================================================================================================================
# Monitoring Enhancement Outputs
# ================================================================================================================

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard (if enhanced monitoring is enabled)."
  value       = var.enable_enhanced_monitoring ? "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.lambda_edge_dashboard[0].dashboard_name}" : null
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts (if email notifications are configured)."
  value       = var.enable_enhanced_monitoring && length(var.alarm_notification_emails) > 0 ? aws_sns_topic.lambda_alerts[0].arn : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group (if enhanced monitoring is enabled)."
  value       = var.enable_enhanced_monitoring ? aws_cloudwatch_log_group.lambda_edge_logs[0].name : null
}

output "error_alarm_name" {
  description = "Name of the error rate CloudWatch alarm (if enhanced monitoring is enabled)."
  value       = var.enable_enhanced_monitoring ? aws_cloudwatch_metric_alarm.lambda_error_rate[0].alarm_name : null
}

output "duration_alarm_name" {
  description = "Name of the duration CloudWatch alarm (if enhanced monitoring is enabled)."
  value       = var.enable_enhanced_monitoring ? aws_cloudwatch_metric_alarm.lambda_duration[0].alarm_name : null
}

output "throttle_alarm_name" {
  description = "Name of the throttle CloudWatch alarm (if enhanced monitoring is enabled)."
  value       = var.enable_enhanced_monitoring ? aws_cloudwatch_metric_alarm.lambda_throttles[0].alarm_name : null
}

# ================================================================================================================
# Useful Information Outputs
# ================================================================================================================

output "lambda_config_mode" {
  description = "The configuration mode used for the Lambda function."
  value       = var.lambda_config_mode
}

output "security_enhancements_enabled" {
  description = "Map of enabled security enhancements."
  value = {
    secrets_manager  = var.use_secrets_manager
    vpc_config       = var.enable_vpc_config
    audit_logging    = var.enable_audit_logging
    kms_key_rotation = local.create_ssm_parameter
  }
}

output "monitoring_enhancements_enabled" {
  description = "Map of enabled monitoring enhancements."
  value = {
    enhanced_monitoring = var.enable_enhanced_monitoring
    email_notifications = length(var.alarm_notification_emails) > 0
    dashboard           = var.enable_enhanced_monitoring
    custom_log_group    = var.enable_enhanced_monitoring
  }
}
