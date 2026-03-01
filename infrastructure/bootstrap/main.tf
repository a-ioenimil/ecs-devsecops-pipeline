terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1" # REPLACE_ME: Update to your desired AWS region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "aurascale-terraform-remote-state-12345" # REPLACE_ME: ensure bucket name is globally unique
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# The latest AWS S3 backend supports native state locking using the s3 bucket itself (since Terraform 1.2.3 and AWS provider 5.38.0).
# Thus, no DynamoDB table is required for locking anymore.
# Run `terraform init` and `terraform apply` in this directory first.
