# ================================================================================================================
# Security Enhancements - Secrets Manager Integration
# ================================================================================================================

# Secrets Manager for sensitive configuration
resource "aws_secretsmanager_secret" "lambda_secrets" {
  count                   = var.use_secrets_manager ? 1 : 0
  name                    = "${var.name}-lambda-edge-secrets"
  description             = "Sensitive configuration for Lambda@Edge Cognito authentication"
  recovery_window_in_days = var.secrets_recovery_window_days

  tags = merge(var.tags, {
    Purpose = "Lambda@Edge Cognito Authentication"
    Module  = "terraform-aws-lambda-at-edge-cognito-authentication"
  })
}

resource "aws_secretsmanager_secret_version" "lambda_secrets" {
  count     = var.use_secrets_manager ? 1 : 0
  secret_id = aws_secretsmanager_secret.lambda_secrets[0].id

  secret_string = jsonencode({
    cognito_user_pool_app_client_secret = var.cognito_user_pool_app_client_secret
    # Add other sensitive values here as needed
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Enhanced KMS key with better security policies
resource "aws_kms_key" "enhanced_ssm_kms_key" {
  count                   = local.create_ssm_parameter ? 1 : 0
  description             = "KMS key for ${var.name} Lambda@Edge SSM parameters with enhanced security"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda@Edge to decrypt"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_at_edge.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.us-east-1.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Purpose = "Lambda@Edge SSM Parameter Encryption"
    Module  = "terraform-aws-lambda-at-edge-cognito-authentication"
  })
}

resource "aws_kms_alias" "enhanced_ssm_kms_key" {
  count         = local.create_ssm_parameter ? 1 : 0
  name          = "alias/${var.name}-lambda-edge-ssm"
  target_key_id = aws_kms_key.enhanced_ssm_kms_key[0].key_id
}

# Security group for VPC Lambda (if needed in future)
resource "aws_security_group" "lambda_security_group" {
  count       = var.enable_vpc_config ? 1 : 0
  name_prefix = "${var.name}-lambda-edge-sg"
  description = "Security group for Lambda@Edge function"
  vpc_id      = var.vpc_id

  # Outbound HTTPS only
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound for AWS API calls"
  }

  # Outbound DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS resolution"
  }

  tags = merge(var.tags, {
    Name    = "${var.name}-lambda-edge-sg"
    Purpose = "Lambda@Edge Security Group"
    Module  = "terraform-aws-lambda-at-edge-cognito-authentication"
  })
}

# CloudTrail for audit logging (optional)
resource "aws_cloudtrail" "lambda_audit_trail" {
  count                         = var.enable_audit_logging ? 1 : 0
  name                          = "${var.name}-lambda-edge-audit"
  s3_bucket_name                = aws_s3_bucket.audit_logs[0].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
    data_resource {
      type   = "AWS::Lambda::Function"
      values = [aws_lambda_function.cloudfront_auth_edge.arn]
    }
  }

  tags = merge(var.tags, {
    Purpose = "Lambda@Edge Audit Logging"
    Module  = "terraform-aws-lambda-at-edge-cognito-authentication"
  })
}

resource "aws_s3_bucket" "audit_logs" {
  count  = var.enable_audit_logging ? 1 : 0
  bucket = "${var.name}-lambda-edge-audit-logs-${random_id.bucket_suffix[0].hex}"

  tags = merge(var.tags, {
    Purpose = "Lambda@Edge Audit Logs"
    Module  = "terraform-aws-lambda-at-edge-cognito-authentication"
  })
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  count  = var.enable_audit_logging ? 1 : 0
  bucket = aws_s3_bucket.audit_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  count  = var.enable_audit_logging ? 1 : 0
  bucket = aws_s3_bucket.audit_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  count  = var.enable_audit_logging ? 1 : 0
  bucket = aws_s3_bucket.audit_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_id" "bucket_suffix" {
  count       = var.enable_audit_logging ? 1 : 0
  byte_length = 4
}
