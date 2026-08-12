resource "aws_sns_topic" "order_events" {
  name = "order-events-topic"
}

resource "aws_sns_topic_policy" "order_events" {
  arn = aws_sns_topic.order_events.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridgePublish"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.order_events.arn
    }]
  })
}

locals {
  consumers = ["email", "warehouse", "inventory"]
}

resource "aws_sqs_queue" "dlq" {
  for_each = toset(local.consumers)
  name     = "${each.key}-queue-dlq"
}

resource "aws_sqs_queue" "main" {
  for_each                  = toset(local.consumers)
  name                       = "${each.key}-queue"
  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount      = 3
  })
}

resource "aws_sns_topic_subscription" "queue_subscriptions" {
  for_each  = toset(local.consumers)
  topic_arn = aws_sns_topic.order_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main[each.key].arn
}

resource "aws_sqs_queue_policy" "allow_sns" {
  for_each  = toset(local.consumers)
  queue_url = aws_sqs_queue.main[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSNSPublish"
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.main[each.key].arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.order_events.arn
        }
      }
    }]
  })
}
