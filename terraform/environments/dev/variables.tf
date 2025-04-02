variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "784866907805" # Replace with your actual AWS account ID
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cloudguru-app"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "bastion_allowed_cidr" {
  description = "CIDR block allowed to access the bastion host"
  type        = string
  default     = "0.0.0.0/0" # This should be replaced with your IP
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key" {
  description = "SSH public key for the bastion host"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCoWCjBWPcpJAdt0pAMgd+V2Y29qAp3IHbRBd5fHcCSHzA3E9rClbGcfQTG2MnV5yjVi/BzYauZPpYtWSEd2Os5/ZdtFkKJjV5I96JPADztN5TtUfFTEWv3qga420shIKhZ+64/fLk7CH6cci7YoJbzKsAKbiFgzl6FpwZXECz4/mhOcUNvuRERSfGkgGpCkn3m0RkAv3+ISw9yBjSp9aqtD+O+Y0wkW6tir2f/QqDN1i4L+IWGapDBm7OeuQZ6llWBbhswFMK088Ney7gi0hc+hLCM4lKkmyAKk/nIMW7gOVfxaQBGV2VO1T7a55XGYaOuLbPInb8nPgvhGgQEhW2B avichayef@newserver4"
}

variable "app_container_image" {
  description = "Container image for the application"
  type        = string
  default     = "nginx:latest" # Replace with your app image
}

variable "app_container_port" {
  description = "Port the backend container exposes"
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Path for ALB health check"
  type        = string
  default     = "/health"
}

variable "app_count" {
  description = "Number of app instances to run"
  type        = number
  default     = 2
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "Fargate instance memory"
  type        = number
  default     = 512
}

variable "app_secrets" {
  description = "Secrets for the application"
  type        = map(string)
  default = {
    # These are placeholders and should be replaced with actual secrets
    "DB_PASSWORD" = "placeholder"
    "API_KEY"     = "placeholder"
  }
  sensitive = true
}
