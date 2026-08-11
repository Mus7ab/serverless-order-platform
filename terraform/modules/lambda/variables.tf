variable "role_arn" {
  description = "ARN of the IAM role this Lambda assumes"
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name passed as an environment variable"
  type        = string
}

variable "event_bus_name" {
  description = "Name of the EventBridge bus passed as an environment variable"
  type        = string
}
