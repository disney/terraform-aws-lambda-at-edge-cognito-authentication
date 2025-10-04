plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

config {
  # Enables module inspection
  module = true
  
  # Enables deep check mode
  deep_check = true
  
  # Enables variable files
  varfile = ["terraform.tfvars", "*.auto.tfvars"]
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_standard_module_structure" {
  enabled = true
}

# AWS specific rules
rule "aws_instance_invalid_type" {
  enabled = true
}

rule "aws_lambda_function_invalid_runtime" {
  enabled = true
}

rule "aws_s3_bucket_invalid_acl" {
  enabled = true
}

rule "aws_iam_policy_document_gov_friendly_arns" {
  enabled = true
}

rule "aws_iam_role_policy_too_long" {
  enabled = true
}

rule "aws_security_group_rule_invalid_protocol" {
  enabled = true
}

# Security rules
rule "aws_s3_bucket_public_read_prohibited" {
  enabled = true
}

rule "aws_s3_bucket_public_write_prohibited" {
  enabled = true
}

rule "aws_cloudtrail_enabled" {
  enabled = true
}

rule "aws_kms_key_rotation_enabled" {
  enabled = true
}
