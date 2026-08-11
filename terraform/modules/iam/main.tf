data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "order_handler" {
  name               = "order-handler-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem"
    ]
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_role_policy" "dynamodb_access" {
  name   = "order-handler-dynamodb-access"
  role   = aws_iam_role.order_handler.id
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.order_handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
data "aws_iam_policy_document" "eventbridge_access" {
  statement {
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [var.event_bus_arn]
  }
}

resource "aws_iam_role_policy" "eventbridge_access" {
  name   = "order-handler-eventbridge-access"
  role   = aws_iam_role.order_handler.id
  policy = data.aws_iam_policy_document.eventbridge_access.json
}
