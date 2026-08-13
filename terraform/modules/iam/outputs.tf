output "role_arn" {
  description = "ARN of the order-handler Lambda execution role"
  value       = aws_iam_role.order_handler.arn
}

output "role_name" {
  description = "Name of the order-handler Lambda execution role"
  value       = aws_iam_role.order_handler.name
}

output "consumer_role_arns" {
  description = "Map of consumer name to its IAM role ARN"
  value       = { for k, v in aws_iam_role.consumers : k => v.arn }
}
