output "qualified_arn" {
  description = "Qualified ARN for the Lambda@Edge created by this module."
  value       = aws_lambda_function.cloudfront_auth_edge.qualified_arn
}

output "arn" {
  description = "ARN for the Lambda@Edge created by this module."
  value       = aws_lambda_function.cloudfront_auth_edge.arn
}

output "function_name" {
  description = "Name of the Lambda@Edge created by this module."
  value       = aws_lambda_function.cloudfront_auth_edge.function_name
}
