terraform {
  required_providers {
    aws = {
      version = "= 3.3.0"
    }
  }
}


# Brainboard aliases for AWS regions
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}
provider "aws" {
  alias  = "eu-central-1"
  region = "eu-central-1"
}
