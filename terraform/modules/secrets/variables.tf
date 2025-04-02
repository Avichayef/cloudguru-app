variable "app_secrets" {
  description = "Secrets for the application"
  type        = map(string)
  sensitive   = true
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}
