# ================================================================================================================
# General Configurations
# ================================================================================================================

variable "name" {
  description = "Name to prefix on all infrastructure created by this module."
  type        = string
}

variable "tags" {
  description = "Map of tags to attach to all AWS resources created by this module."
  type        = map(string)
  default     = {}
}

# ================================================================================================================
# Cloudwatch Configurations
# ================================================================================================================

variable "cloudwatch_enable_log_group_create" {
  description = "Allow Lambda@Edge to create log groups in cloudwatch, defaults to true."
  type        = bool
  default     = true
}

# ================================================================================================================
# Lambda Configurations
# ================================================================================================================

variable "lambda_runtime" {
  description = "Lambda runtime to utilize for Lambda@Edge."
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_timeout" {
  description = "Amount of timeout in seconds to set on for Lambda@Edge."
  type        = number
  default     = 5
}

variable "lambda_config_mode" {
  description = "Which strategy to use to supply config to the lambda function, defaults to 'dynamic'."
  type        = string
  default     = "dynamic"
  validation {
    condition     = contains(["dynamic", "hybrid", "static"], var.lambda_config_mode)
    error_message = "Input var.lambda_config_mode must be one of \"dynamic\", \"hybrid\", \"static\"."
  }
}

variable "lambda_config_allow_insecure_secret_storage" {
  description = "Allow secrets to be stored in the lambda config file, defaults to false."
  type        = bool
  default     = false
}

# ================================================================================================================
# Cognito @ Edge Configurations
# ================================================================================================================

variable "cognito_user_pool_name" {
  description = "Name of the Cognito User Pool to utilize. Required if 'cognito_user_pool_domain' is not set."
  type        = string
  default     = ""
}

variable "cognito_user_pool_domain" {
  description = "Optional: Full Domain of the Cognito User Pool to utilize. Mutually exclusive with 'cognito_user_pool_name'."
  type        = string
  default     = ""
}

variable "cognito_user_pool_region" {
  description = "AWS region where the cognito user pool was created."
  type        = string
  default     = "us-west-2"
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID for the targeted user pool."
  type        = string
}

variable "cognito_user_pool_app_client_id" {
  description = "Cognito User Pool App Client ID for the targeted user pool."
  type        = string
}

variable "cognito_user_pool_app_client_secret" {
  description = "Cognito User Pool App Client Secret for the targeted user pool. NOTE: This is currently not compatible with AppSync applications."
  type        = string
  default     = null
}

variable "cognito_cookie_expiration_days" {
  description = "Number of days to keep the cognito cookie valid."
  type        = number
  default     = 7
}

variable "cognito_disable_cookie_domain" {
  description = "Sets domain attribute in cookies, defaults to false."
  type        = bool
  default     = false
}

variable "cognito_log_level" {
  description = "Logging level. Default: 'silent'"
  type        = string
  default     = "silent"

  validation {
    condition     = contains(["fatal", "error", "warn", "info", "debug", "trace", "silent"], var.cognito_log_level)
    error_message = "Cognito Log Level must be one of: ['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']."
  }
}

variable "cognito_redirect_path" {
  description = "Optional path to redirect to after a successful cognito login."
  type        = string
  default     = ""
}

variable "cognito_additional_settings" {
  description = "Map of any to configure any additional cognito@edge parameters not handled by this module."
  type        = any
  default     = {}
}

# ================================================================================================================
# Security Enhancement Variables
# ================================================================================================================

variable "use_secrets_manager" {
  description = "Use AWS Secrets Manager for sensitive configuration instead of SSM Parameter Store only."
  type        = bool
  default     = false
}

variable "secrets_recovery_window_days" {
  description = "Number of days to retain deleted secrets before permanent deletion."
  type        = number
  default     = 7

  validation {
    condition     = var.secrets_recovery_window_days >= 7 && var.secrets_recovery_window_days <= 30
    error_message = "Secrets recovery window must be between 7 and 30 days."
  }
}

variable "kms_deletion_window_days" {
  description = "Number of days to retain KMS key before deletion."
  type        = number
  default     = 10

  validation {
    condition     = var.kms_deletion_window_days >= 7 && var.kms_deletion_window_days <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "enable_vpc_config" {
  description = "Enable VPC configuration for Lambda function (future use)."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for Lambda security group (required if enable_vpc_config is true)."
  type        = string
  default     = ""
}

variable "enable_audit_logging" {
  description = "Enable CloudTrail audit logging for Lambda function."
  type        = bool
  default     = false
}

# ================================================================================================================
# Monitoring Enhancement Variables  
# ================================================================================================================

variable "enable_enhanced_monitoring" {
  description = "Enable enhanced CloudWatch monitoring and dashboards."
  type        = bool
  default     = true
}

variable "alarm_notification_emails" {
  description = "List of email addresses to receive alarm notifications."
  type        = list(string)
  default     = []
}

variable "error_rate_threshold" {
  description = "Error rate threshold (percentage) for CloudWatch alarms."
  type        = number
  default     = 5.0

  validation {
    condition     = var.error_rate_threshold > 0 && var.error_rate_threshold <= 100
    error_message = "Error rate threshold must be between 0 and 100."
  }
}

variable "duration_threshold_ms" {
  description = "Duration threshold (milliseconds) for CloudWatch alarms."
  type        = number
  default     = 4000

  validation {
    condition     = var.duration_threshold_ms > 0 && var.duration_threshold_ms <= 5000
    error_message = "Duration threshold must be between 0 and 5000 milliseconds (Lambda@Edge limit is 5s)."
  }
}

# ================================================================================================================
# Code Quality Enhancement Variables
# ================================================================================================================

variable "enable_code_quality_checks" {
  description = "Enable additional code quality and security checks."
  type        = bool
  default     = true
}
