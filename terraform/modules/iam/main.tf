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

locals {
  consumers = ["email", "warehouse", "inventory"]
}

resource "aws_iam_role" "consumers" {
  for_each           = toset(local.consumers)
  name               = "${each.key}-notifier-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "consumer_sqs_access" {
  for_each = toset(local.consumers)

  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [var.queue_arns[each.key]]
  }
}

resource "aws_iam_role_policy" "consumer_sqs_access" {
  for_each = toset(local.consumers)
  name     = "${each.key}-notifier-sqs-access"
  role     = aws_iam_role.consumers[each.key].id
  policy   = data.aws_iam_policy_document.consumer_sqs_access[each.key].json
}

resource "aws_iam_role_policy_attachment" "consumer_basic_execution" {
  for_each   = toset(local.consumers)
  role       = aws_iam_role.consumers[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "order_handler_xray" {
  role       = aws_iam_role.order_handler.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy_attachment" "consumer_xray" {
  for_each   = toset(local.consumers)
  role       = aws_iam_role.consumers[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
