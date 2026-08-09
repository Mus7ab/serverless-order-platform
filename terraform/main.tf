module "dynamodb" {
  source = "./modules/dynamodb"

  table_name   = "orders"
  billing_mode = "PAY_PER_REQUEST"

  tags = {
    Project     = "serverless-order-platform"
    Environment = "dev"
  }
}

module "iam" {
  source = "./modules/iam"

  dynamodb_table_arn = module.dynamodb.table_arn
}

module "lambda" {
  source = "./modules/lambda"

  role_arn   = module.iam.role_arn
  table_name = module.dynamodb.table_name
}
