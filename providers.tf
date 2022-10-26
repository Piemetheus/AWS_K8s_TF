terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


# SAS aliases for AWS regions
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}
provider "aws" {
  alias  = "eu-central-1"
  region = "eu-central-1"
}
