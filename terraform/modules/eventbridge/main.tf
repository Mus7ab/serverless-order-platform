resource "aws_cloudwatch_event_bus" "orders" {
  name = "orders-event-bus"
}

resource "aws_cloudwatch_event_rule" "order_placed" {
  name           = "order-placed-rule"
  event_bus_name = aws_cloudwatch_event_bus.orders.name

  event_pattern = jsonencode({
    source      = ["order-handler"]
    detail-type = ["OrderPlaced"]
  })
}

resource "aws_cloudwatch_log_group" "order_events" {
  name              = "/aws/events/order-placed"
  retention_in_days = 3
}

resource "aws_cloudwatch_event_target" "log_group" {
  rule           = aws_cloudwatch_event_rule.order_placed.name
  event_bus_name = aws_cloudwatch_event_bus.orders.name
  arn            = aws_cloudwatch_log_group.order_events.arn
}

resource "aws_cloudwatch_log_resource_policy" "eventbridge_to_logs" {
  policy_name = "eventbridge-to-cloudwatch-logs"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EventBridgeToCWLogs"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = ["logs:PutLogEvents", "logs:CreateLogStream"]
      Resource  = "${aws_cloudwatch_log_group.order_events.arn}:*"
    }]
  })
}
