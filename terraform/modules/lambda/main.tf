data "archive_file" "order_handler" {
  type        = "zip"
  source_dir  = "${path.module}/../../../src/order-handler"
  output_path = "${path.module}/order-handler.zip"
}

resource "aws_lambda_function" "order_handler" {
  function_name    = "order-handler"
  role             = var.role_arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 10
  filename         = data.archive_file.order_handler.output_path
  source_code_hash = data.archive_file.order_handler.output_base64sha256

  environment {
    variables = {
      TABLE_NAME     = var.table_name
      EVENT_BUS_NAME = var.event_bus_name
    }
  }

  tracing_config {
    mode = "Active"
  }
}

locals {
  consumers = ["email", "warehouse", "inventory"]
}

data "archive_file" "consumers" {
  for_each    = toset(local.consumers)
  type        = "zip"
  source_dir  = "${path.module}/../../../src/${each.key}-notifier"
  output_path = "${path.module}/${each.key}-notifier.zip"
}

resource "aws_lambda_function" "consumers" {
  for_each         = toset(local.consumers)
  function_name    = "${each.key}-notifier"
  role             = var.consumer_role_arns[each.key]
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 10
  filename         = data.archive_file.consumers[each.key].output_path
  source_code_hash = data.archive_file.consumers[each.key].output_base64sha256

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_event_source_mapping" "consumers" {
  for_each         = toset(local.consumers)
  event_source_arn = var.queue_arns[each.key]
  function_name    = aws_lambda_function.consumers[each.key].arn
  batch_size       = 10
}
