# ==========================================
# TERRAFORM & PROVIDER CONFIGURATION
# ==========================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "aurascale-terraform-remote-state-12345" # REPLACE_ME: Bucket name from bootstrap phase
    key          = "actual-environment/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}