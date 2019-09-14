provider "aws" {
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
  region     = var.AWS_REGION
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-tejas"
    key            = "juno-ssm-doc"
    region         = "us-east-2"
    dynamodb_table = "bryce-struts-tejas"
  }
}

