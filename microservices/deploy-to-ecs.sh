#!/bin/bash

# This script deploys the microservices to ECS Fargate

# Exit on error
set -e

# Function to clean up on error
cleanup() {
  echo "Error occurred. Cleaning up resources..."
  cd "$TERRAFORM_DIR"
  terraform init
  terraform destroy -auto-approve || {
    echo "Some resources could not be destroyed. They may already be gone or in the process of being deleted."
    echo "You may need to manually check and clean up any remaining resources in the AWS console."
  }
  exit 1
}

# Set variables
AWS_REGION="us-east-1"  # Change to your AWS region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROJECT_NAME="cloudguru-app"
ENVIRONMENT="dev"
TERRAFORM_DIR="$(pwd)/../terraform/environments/dev"

# Trap errors
trap cleanup ERR

# Update the AWS account ID in the Terraform variables
echo "Updating AWS account ID in Terraform variables..."
sed -i "s/123456789012/$AWS_ACCOUNT_ID/g" "$TERRAFORM_DIR/variables.tf"

# Build and push Docker images to ECR
echo "Building and pushing Docker images to ECR..."
./push-to-ecr.sh

# Apply Terraform to deploy to ECS
echo "Deploying to ECS with Terraform..."
cd "$TERRAFORM_DIR"
terraform init

# Try to apply Terraform, with retry logic for transient errors
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if terraform apply -auto-approve; then
    echo "Terraform apply succeeded!"
    break
  else
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
      echo "Terraform apply failed. Retrying in 30 seconds... (Attempt $RETRY_COUNT of $MAX_RETRIES)"
      sleep 30
    else
      echo "Terraform apply failed after $MAX_RETRIES attempts."
      exit 1
    fi
  fi
done

# Get the ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "ALB DNS not available")

echo "Deployment complete!"
if [ "$ALB_DNS" != "ALB DNS not available" ]; then
  echo "Your application is available at: http://$ALB_DNS"
else
  echo "ALB DNS not available. Check for errors in the deployment."
fi
