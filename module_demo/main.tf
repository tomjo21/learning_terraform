provider "aws" {
  region = "us-east-1"
}

module "ec2_instance" {
  source = "./module_demo/ec2_instance"
  ami_value = "ami-....." # replace this
  instance_type_value = "t2.micro"
  subnet_id_value = "subnet-......." # replace this
}