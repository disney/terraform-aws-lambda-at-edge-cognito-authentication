output "qualified_arn" {
  description = "Qualified ARN for the lambda@edge created by this module."
  value       = aws_lambda_function.cloudfront_auth_edge.qualified_arn
}

output "arn" {
  description = "ARN for the lambda@edge created by this module."
  value       = aws_lambda_function.cloudfront_auth_edge.arn
}
