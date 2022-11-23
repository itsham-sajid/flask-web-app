# Configuring Terraform Backend

terraform {
  backend "s3" {
    bucket         = "terraform-backend-itsham-sajid"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "tf-backend-webapp"

  }
}
