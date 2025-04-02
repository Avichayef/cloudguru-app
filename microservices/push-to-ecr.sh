#!/bin/bash

# This script builds and pushes the Docker images to AWS ECR

# Set variables
AWS_REGION="us-east-1"  # Change to your AWS region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_BACKEND_REPO="microservices/backend"
ECR_PROXY_REPO="microservices/proxy"

# Create ECR repositories if they don't exist
echo "Creating ECR repositories if they don't exist..."
aws ecr describe-repositories --repository-names $ECR_BACKEND_REPO --region $AWS_REGION || \
    aws ecr create-repository --repository-name $ECR_BACKEND_REPO --region $AWS_REGION

aws ecr describe-repositories --repository-names $ECR_PROXY_REPO --region $AWS_REGION || \
    aws ecr create-repository --repository-name $ECR_PROXY_REPO --region $AWS_REGION

# Authenticate Docker to ECR
echo "Authenticating Docker to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build the Docker images
echo "Building Docker images..."
docker-compose build

# Tag the images
echo "Tagging images for ECR..."
docker tag microservices_backend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND_REPO:latest
docker tag microservices_proxy:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_PROXY_REPO:latest

# Push the images to ECR
echo "Pushing images to ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND_REPO:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_PROXY_REPO:latest

echo "Done! Images have been pushed to ECR."
