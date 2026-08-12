module "dynamodb" {
  source = "./modules/dynamodb"

  table_name   = "orders"
  billing_mode = "PAY_PER_REQUEST"

  tags = {
    Project     = "serverless-order-platform"
    Environment = "dev"
  }
}

module "sns_sqs" {
  source = "./modules/sns-sqs"
}

module "eventbridge" {
  source = "./modules/eventbridge"

  sns_topic_arn = module.sns_sqs.topic_arn
}

module "iam" {
  source = "./modules/iam"

  dynamodb_table_arn = module.dynamodb.table_arn
  event_bus_arn       = module.eventbridge.event_bus_arn
}

module "lambda" {
  source = "./modules/lambda"

  role_arn       = module.iam.role_arn
  table_name     = module.dynamodb.table_name
  event_bus_name = module.eventbridge.event_bus_name
}

module "api_gateway" {
  source = "./modules/api-gateway"

  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
}
