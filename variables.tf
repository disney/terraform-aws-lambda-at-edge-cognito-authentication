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
  type        = map(any)
  default     = {}
}

