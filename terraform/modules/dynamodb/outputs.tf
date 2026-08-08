output "table_name" {
  description = "Name of the DynamoDB orders table"
  value       = aws_dynamodb_table.orders.name
}

output "table_arn" {
  description = "ARN of the DynamoDB orders table"
  value       = aws_dynamodb_table.orders.arn
}

output "gsi_name" {
  description = "Name of the customer-orders GSI"
  value       = "customer-orders-index"
}
