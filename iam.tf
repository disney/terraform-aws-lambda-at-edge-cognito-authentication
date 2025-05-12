data "aws_caller_identity" "current" {}

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

resource "aws_iam_role_policy" "lambda_edge_self_role_read" {
  name = "LambdaEdgeSelfRoleRead"
  role = aws_iam_role.lambda_at_edge.id

  policy = data.aws_iam_policy_document.allow_lambda_edge_self_role_read.json
}

data "aws_iam_policy_document" "allow_lambda_edge_self_role_read" {
  statement {
    actions   = ["iam:GetRolePolicy"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name}-lambda-edge-role"]
  }
  statement {
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ssm_parameter_permission_for_lambda_auth" {
  count = local.create_ssm_parameter ? 1 : 0
  name  = "SSM_PARAMETER_PERMISSION_FOR_LAMBDA_AUTH"
  role  = aws_iam_role.lambda_at_edge.id

  policy = data.aws_iam_policy_document.allow_ssm_parameter_permission_for_lambda_auth.json
}

data "aws_iam_policy_document" "allow_ssm_parameter_permission_for_lambda_auth" {
  dynamic "statement" {
    for_each = local.create_ssm_parameter ? [1] : []
    content {
      actions   = ["ssm:GetParameter"]
      resources = [aws_ssm_parameter.lambda_configuration_parameters[0].arn]
    }
  }
}

resource "aws_iam_role_policy" "ssm_parameter_decrypt" {
  count = local.create_ssm_parameter ? 1 : 0
  name  = "ssmParameterDecrypt"
  role  = aws_iam_role.lambda_at_edge.id

  policy = data.aws_iam_policy_document.allow_ssm_parameter_decrypt.json
}

data "aws_iam_policy_document" "allow_ssm_parameter_decrypt" {
  dynamic "statement" {
    for_each = local.create_ssm_parameter ? [1] : []
    content {
      actions   = ["kms:Decrypt"]
      resources = [aws_kms_key.ssm_kms_key[0].arn]
    }
  }
}
