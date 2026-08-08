module "dynamodb" {
  source = "./modules/dynamodb"

  table_name   = "orders"
  billing_mode = "PAY_PER_REQUEST"

  tags = {
    Project     = "serverless-order-platform"
    Environment = "dev"
  }
}
