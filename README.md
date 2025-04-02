# CloudGuru Home Task

This repository contains the infrastructure as code (Terraform) for deploying a microservice-based application to AWS.

## Infrastructure Components

The infrastructure includes:

- VPC with public and private subnets
- NAT Gateway for private subnet internet access
- EC2 Bastion Host in a public subnet
- ECS Fargate cluster in private subnets
- Application Load Balancer (ALB)
- IAM roles and policies with least privilege
- AWS Secrets Manager for storing application secrets

## Project Structure

```
terraform/
├── modules/                # Reusable Terraform modules
│   ├── vpc/                # VPC, subnets, NAT Gateway
│   ├── security/           # Security groups
│   ├── bastion/            # EC2 Bastion Host
│   ├── ecs/                # ECS Fargate cluster and service
│   ├── alb/                # Application Load Balancer
│   ├── iam/                # IAM roles and policies
│   └── secrets/            # AWS Secrets Manager
└── environments/           # Environment-specific configurations
    └── dev/                # Development environment
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform v1.0.0 or newer
- SSH key pair for accessing the bastion host

## Usage

### Initialize Terraform

```bash
cd terraform/environments/dev
terraform init
```

### Plan the deployment

```bash
terraform plan -out=tfplan
```

### Apply the changes

```bash
terraform apply tfplan
```

### Destroy the infrastructure

```bash
terraform destroy
```

## Remote State (Optional)

To enable remote state with S3 and DynamoDB locking:

1. Create an S3 bucket and DynamoDB table:

```bash
aws s3 mb s3://terraform-state-cloudguru-app
aws dynamodb create-table \
    --table-name terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
```

2. Uncomment the backend configuration in `terraform/environments/dev/main.tf`

## Security Considerations

- Update the `bastion_allowed_cidr` variable with your IP address
- Replace placeholder secrets in `app_secrets` with actual secrets
- Consider using AWS KMS for encrypting secrets
- Rotate SSH keys and secrets regularly

## Outputs

After applying the Terraform configuration, you'll get the following outputs:

- VPC ID
- Public and private subnet IDs
- Bastion host public IP
- ALB DNS name
- ECS cluster and service names
