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

  inline_policy {
    name = "AllowCloudwatchLogs"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:CreateLogGroup"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  inline_policy {
    name = "LambdaEdgeSelfRoleRead"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["iam:GetRolePolicy"]
          Effect   = "Allow"
          Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name}-lambda-edge-role"
        },
        {
          Action   = ["sts:GetCallerIdentity"]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  inline_policy {
    name = "SSM_PARAMETER_PERMISSION_FOR_LAMBDA_AUTH"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["ssm:GetParameter"]
          Effect   = "Allow"
          Resource = aws_ssm_parameter.lambda_configuration_parameters.arn
        },
      ]
    })
  }

  inline_policy {
    name = "ssmParameterDecrypt"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["kms:Decrypt"]
          Effect   = "Allow"
          Resource = aws_kms_key.ssm_kms_key.arn
        },
      ]
    })
  }
}
