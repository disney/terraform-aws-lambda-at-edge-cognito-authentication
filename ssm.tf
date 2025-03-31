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
    parseAuthPath        = var.cognito_redirect_path
  }, var.cognito_additional_settings)
}

resource "aws_kms_key" "ssm_kms_key" {
  count                   = var.lambda_ship_config ? 0 : 1
  description             = "KMS Encryption key for ${var.name} lambda-edge auth"
  deletion_window_in_days = 7
  tags                    = var.tags
  enable_key_rotation     = true
}

resource "aws_ssm_parameter" "lambda_configuration_parameters" {
  count       = var.lambda_ship_config ? 0 : 1
  name        = "/${var.name}/lambda/edge/configuration"
  description = "Lambda@Edge Configuration for Application[${var.name}]"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_kms_key[0].key_id
  value       = jsonencode(local.lambda_configuration)
  tags        = var.tags
}

resource "local_file" "lambda_configuration" {
  count    = var.lambda_ship_config ? 1 : 0
  filename = "${path.module}/files/deployable/dist/${local.lambda_config_file}"
  content  = jsonencode(local.lambda_configuration)
}
