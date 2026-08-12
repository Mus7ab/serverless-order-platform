output "topic_arn" {
  description = "ARN of the order-events SNS topic"
  value       = aws_sns_topic.order_events.arn
}

output "queue_arns" {
  description = "Map of consumer name to main queue ARN"
  value       = { for k, v in aws_sqs_queue.main : k => v.arn }
}

output "queue_urls" {
  description = "Map of consumer name to main queue URL"
  value       = { for k, v in aws_sqs_queue.main : k => v.url }
}

output "dlq_arns" {
  description = "Map of consumer name to DLQ ARN"
  value       = { for k, v in aws_sqs_queue.dlq : k => v.arn }
}
