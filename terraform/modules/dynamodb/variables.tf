variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "orders"
}

variable "billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "tags" {
  description = "Tags to apply to the table"
  type        = map(string)
  default     = {}
}
