terraform {
  backend "s3" {
    bucket         = "tom-s3-demo" # change this
    key            = "tom/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}