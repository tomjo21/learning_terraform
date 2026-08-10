provider "aws" {
  region = "us-east-1"  # Set your desired AWS region
}

resource "aws_instance" "example" {
  ami           = "ami_id"  # Specify an appropriate AMI ID
  instance_type = "t2.micro"
  subnet_id     = "subnet-id"
  key_name      = "aws_key"
}