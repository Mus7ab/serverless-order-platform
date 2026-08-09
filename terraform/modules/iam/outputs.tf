output "role_arn" {
  description = "ARN of the order-handler Lambda execution role"
  value       = aws_iam_role.order_handler.arn
}

output "role_name" {
  description = "Name of the order-handler Lambda execution role"
  value       = aws_iam_role.order_handler.name
}
