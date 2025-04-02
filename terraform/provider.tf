provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Uncomment this block to enable remote state
  # backend "s3" {
  #   bucket         = "terraform-state-${var.project_name}"
  #   key            = "terraform.tfstate"
  #   region         = var.aws_region
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}
