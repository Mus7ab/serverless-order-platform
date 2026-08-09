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
      TABLE_NAME = var.table_name
    }
  }
}
