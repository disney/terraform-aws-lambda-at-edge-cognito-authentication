locals {
  lambda_config_file = "config.json" # if changed, update configFile in files/deployable/index.js as well
  tracked_files = setunion(
    fileset("${path.module}/files/deployable/", "*.{js,json}"),
    fileset("${path.module}/files/deployable/", "dist/${local.lambda_config_file}"),
    fileset("${path.module}/files/deployable/", "patches/*.patch")
  )
  tracked_file_sha = sha256(join(",", [for file in local.tracked_files : filesha256("${path.module}/files/deployable/${file}")]))

  # This is an ugly hack to force terraform plan/apply to fail if the supplied config would put secrets
  # into the lambda config file and the user hasn't set var.lambda_config_allow_insecure_secret_storage.  
  # An alternative would be to use the extended validation introduced in tf v1.9, but forcing that as the
  # minimum required version would be a breaking change and also prevent using the module with opentofu
  assert_static_and_secrets = var.lambda_config_mode == "static" && var.cognito_user_pool_app_client_secret != null && !var.lambda_config_allow_insecure_secret_storage ? file("ERROR: client secrets and lambda_config_mode = static should not be used together!") : null

  # we only create the config file in the lambda bundle if the config mode is 'static' or 'hybrid',
  # this assumes that the assert above will cause terraform to fail if the user combines config mode 'static'
  # with secrets, so we don't need to check for that here.
  include_config_file = var.lambda_config_mode != "dynamic" ? true : false
}

resource "null_resource" "install_lambda_dependencies" {
  provisioner "local-exec" {
    command     = "npm ci"
    working_dir = abspath("${path.module}/files/deployable")
  }

  triggers = {
    deployable_dir = local.tracked_file_sha
  }
}

# the content of the config file for the lambda function, which is shipped along with the lambda
# code if local.include_config_file above evaluates to true (ie if config_mode != 'dynamic).  
# If config_mode is 'static' then the content is all of local.lambda_configuration, otherwise
# config_mode is implicitly 'hybrid' and the content is a single value 'parameterName' which
# contains the name of the SSM parameter that holds the cognito-at-edge configuration.
resource "local_file" "lambda_configuration" {
  count    = local.include_config_file ? 1 : 0
  filename = "${path.module}/files/deployable/dist/${local.lambda_config_file}"

  content = var.lambda_config_mode == "static" ? local.lambda_configuration : jsonencode({
    parameterName = aws_ssm_parameter.lambda_configuration_parameters[0].name
  })
}

data "archive_file" "lambda_edge_bundle" {
  depends_on = [
    null_resource.install_lambda_dependencies,
    local_file.lambda_configuration
  ]

  type             = "zip"
  source_dir       = "${path.module}/files/deployable/dist"
  output_path      = "${path.module}/files/${local.tracked_file_sha}.zip"
  output_file_mode = "0666"
  excludes         = [".gitkeep"]
}

resource "aws_lambda_function" "cloudfront_auth_edge" {
  function_name = "${var.name}-edge-auth"
  role          = aws_iam_role.lambda_at_edge.arn
  filename      = data.archive_file.lambda_edge_bundle.output_path
  runtime       = var.lambda_runtime
  handler       = "index.handler"
  timeout       = var.lambda_timeout
  tags          = var.tags
  publish       = true

  skip_destroy = true
}
