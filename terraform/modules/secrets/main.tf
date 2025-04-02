resource "random_id" "suffix" {
  byte_length = 8
}

# tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "app_secrets" {
  name        = "${var.project_name}-${var.environment}-app-secrets-${random_id.suffix.hex}"
  description = "Secrets for the ${var.project_name} application in ${var.environment} environment"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-secrets"
    Environment = var.environment
  }

  # Force creation of a new secret if one with the same name is being deleted
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id     = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode(var.app_secrets)
}
