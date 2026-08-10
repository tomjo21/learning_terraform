# Multiple Region Implementation in Terraform

You can make use of the `alias` keyword to implement a multi-region infrastructure setup in Terraform.

```hcl
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

resource "aws_instance" "example" {
  ami           = "ami-0123456789abcdef0"
  instance_type = "t2.micro"
  provider      = aws.us-east-1
}

resource "aws_instance" "example2" {
  ami           = "ami-0123456789abcdef0"
  instance_type = "t2.micro"
  provider      = aws.us-west-2
}
```

## How It Works

- Each `provider "aws"` block is given a unique `alias` (e.g., `us-east-1`, `us-west-2`), allowing you to define multiple configurations for the same provider.
- Each `provider` block specifies its own `region`, pointing that alias to a specific AWS region.
- Resources then reference a specific provider alias using the `provider = aws.<alias>` argument, telling Terraform which region to deploy that resource into.
- In this example, `aws_instance.example` is created in `us-east-1`, while `aws_instance.example2` is created in `us-west-2` — both within the same Terraform configuration.

## Notes

- The default (non-aliased) `provider "aws"` block, if present, is used for any resource that doesn't explicitly set a `provider` argument.
- This pattern is commonly used for deploying redundant infrastructure across regions for high availability, disaster recovery, or latency optimization.
- The `provider` argument value should **not** be quoted (`aws.us-east-1`, not `"aws.us-east-1"`) in modern Terraform versions.