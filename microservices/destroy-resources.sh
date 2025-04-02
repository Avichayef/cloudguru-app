#!/bin/bash

# This script destroys all the resources created by Terraform

# Set variables
TERRAFORM_DIR="$(pwd)/../terraform/environments/dev"

# Destroy Terraform resources
echo "Destroying all resources..."
cd "$TERRAFORM_DIR"

# Initialize Terraform if needed
terraform init

# Try to destroy resources, but don't fail if they're already gone
terraform destroy -auto-approve || {
  echo "Some resources could not be destroyed. They may already be gone or in the process of being deleted."
  echo "You may need to manually check and clean up any remaining resources in the AWS console."
  exit 0
}

echo "Resources destroyed successfully!"
