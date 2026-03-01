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
    key          = "actual-environment/terraform.tfstate"
    use_lockfile = true
  }
}
