provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "tom" {
  instance_type = "t2.micro"
  ami = "ami-........" # change this
  subnet_id = "subnet-............" # change this
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "tom-s3-demo" # change this
}

resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}