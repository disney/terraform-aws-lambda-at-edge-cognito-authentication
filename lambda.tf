locals {
  lambda_config_file = "config.json" # if changed, update configFile in files/deployable/index.js as well

  tracked_files    = setunion(fileset("${path.module}/files/deployable/", "*.{js,json}"), fileset("${path.module}/files/deployable/", "patches/*.patch"))
  tracked_file_sha = sha256(join(",", [for file in local.tracked_files : filesha256("${path.module}/files/deployable/${file}")]))
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

# create a config file for the lambda function, which is shipped along with the lambda code - contains
# a single value, the name of the SSM parameter that contains the lambda-at-edge configuration
resource "local_file" "lambda_configuration" {
  filename = "${path.module}/files/deployable/dist/${local.lambda_config_file}"
  content = jsonencode({
    parameterName = aws_ssm_parameter.lambda_configuration_parameters.name
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


