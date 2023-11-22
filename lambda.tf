locals {
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

data "archive_file" "lambda_edge_bundle" {
  depends_on = [null_resource.install_lambda_dependencies]

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


