terraform {
  backend "s3" {
    bucket       = "serverless-order-platform-tfstate-342677169816"
    key          = "serverless-order-platform/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
