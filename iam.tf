data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "allow_lambda_service_assume" {
  statement {
    sid    = "AllowAwsToAssumeRole"
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "lambda_at_edge" {
  name = "${var.name}-lambda-edge-role"
  tags = var.tags

  assume_role_policy = data.aws_iam_policy_document.allow_lambda_service_assume.json
}

resource "aws_iam_role_policy" "allow_cloudwatch_logs" {
  name = "AllowCloudwatchLogs"
  role = aws_iam_role.lambda_at_edge.id

  policy = data.aws_iam_policy_document.allow_cloudwatch_logs.json
}

data "aws_iam_policy_document" "allow_cloudwatch_logs" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
  dynamic "statement" {
    for_each = var.cloudwatch_enable_log_group_create ? [1] : []
    content {
      actions   = ["logs:CreateLogGroup"]
      resources = ["*"]
    }
  }
}

resource "aws_iam_role_policy" "ssm_parameter_permission_for_lambda_auth" {
  name = "SSM_PARAMETER_PERMISSION_FOR_LAMBDA_AUTH"
  role = aws_iam_role.lambda_at_edge.id

  policy = data.aws_iam_policy_document.allow_ssm_parameter_permission_for_lambda_auth.json
}

data "aws_iam_policy_document" "allow_ssm_parameter_permission_for_lambda_auth" {
  statement {
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.lambda_configuration_parameters.arn]
  }
}

resource "aws_iam_role_policy" "ssm_parameter_decrypt" {
  name = "ssmParameterDecrypt"
  role = aws_iam_role.lambda_at_edge.id

  policy = data.aws_iam_policy_document.allow_ssm_parameter_decrypt.json
}

data "aws_iam_policy_document" "allow_ssm_parameter_decrypt" {
  statement {
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.ssm_kms_key.arn]
  }
}
