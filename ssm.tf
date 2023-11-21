locals {
  lambda_configuration = merge({
    region               = var.cognito_user_pool_region
    userPoolId           = var.cognito_user_pool_id
    userPoolAppId        = var.cognito_user_pool_app_client_id
    userPoolAppSecret    = var.cognito_user_pool_app_client_secret == null ? "" : var.cognito_user_pool_app_client_secret
    userPoolDomain       = coalesce(var.cognito_user_pool_domain, "${var.cognito_user_pool_name}.auth.${var.cognito_user_pool_region}.amazoncognito.com")
    cookieExpirationDays = var.cognito_cookie_expiration_days
    disableCookieDomain  = var.cognito_disable_cookie_domain
    logLevel             = var.cognito_log_level
    redirectPath         = var.cognito_redirect_path
  }, var.cognito_additional_settings)
}

resource "aws_kms_key" "ssm_kms_key" {
  description             = "KMS Encryption key for ${var.name} lambda-edge auth"
  deletion_window_in_days = 7
  tags                    = var.tags
  enable_key_rotation     = true
}

resource "aws_ssm_parameter" "lambda_configuration_parameters" {
  name        = "/${var.name}/lambda/edge/configuration"
  description = "Lambda@Edge Configuration for Application[${var.name}]"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_kms_key.key_id
  value       = jsonencode(local.lambda_configuration)
  tags        = var.tags
}
