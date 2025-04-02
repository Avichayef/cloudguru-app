variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "bastion_allowed_cidr" {
  description = "CIDR block allowed to access the bastion host"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "app_container_port" {
  description = "Port the container exposes"
  type        = number
  default     = 80
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = string
  default     = "10.0.0.0/8"
}
