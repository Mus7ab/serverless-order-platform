variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table this Lambda needs access to"
  type        = string
}
variable "event_bus_arn" {
  description = "ARN of the EventBridge custom bus the Lambda can publish to"
  type        = string
}
