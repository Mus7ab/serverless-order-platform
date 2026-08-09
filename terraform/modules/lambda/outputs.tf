output "function_name" {
  description = "Name of the order-handler Lambda function"
  value       = aws_lambda_function.order_handler.function_name
}

output "function_arn" {
  description = "ARN of the order-handler Lambda function"
  value       = aws_lambda_function.order_handler.arn
}

output "invoke_arn" {
  description = "Invoke ARN, used by API Gateway integration later"
  value       = aws_lambda_function.order_handler.invoke_arn
}
