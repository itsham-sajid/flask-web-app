# Configuring Terraform Backend

terraform {
  backend "s3" {
    bucket         = "bucket-name"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "dynamo-table"

  }
}
