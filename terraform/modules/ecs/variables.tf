variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "The IDs of the private subnets"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "The ID of the ECS security group"
  type        = string
}

variable "execution_role_arn" {
  description = "The ARN of the ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "The ARN of the ECS task role"
  type        = string
}

variable "app_container_image" {
  description = "Container image for the application (legacy)"
  type        = string
  default     = ""
}

variable "backend_container_image" {
  description = "Container image for the backend service"
  type        = string
  default     = "nginx:latest"
}

variable "proxy_container_image" {
  description = "Container image for the proxy service"
  type        = string
  default     = "nginx:latest"
}

variable "app_container_port" {
  description = "Port the container exposes"
  type        = number
}

variable "app_count" {
  description = "Number of app instances to run"
  type        = number
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units"
  type        = number
}

variable "fargate_memory" {
  description = "Fargate instance memory"
  type        = number
}

variable "alb_target_group_arn" {
  description = "The ARN of the ALB target group"
  type        = string
}

variable "secrets_manager_arn" {
  description = "The ARN of the Secrets Manager secret"
  type        = string
}

variable "container_secrets" {
  description = "Secrets to pass to the container"
  type        = map(string)
  default = {
    "DB_PASSWORD" = "placeholder"
    "API_KEY"     = "placeholder"
  }
  sensitive = true
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}
