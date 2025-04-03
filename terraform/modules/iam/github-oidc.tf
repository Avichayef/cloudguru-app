# Use a variable for the OIDC provider ARN instead of a data source
variable "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  type        = string
  default     = "arn:aws:iam::784866907805:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.github_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:Avichayef/cloudguru-app:*"
          }
        }
      }
    ]
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "github_actions_ecs" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "terraform_access" {
  name        = "${var.project_name}-${var.environment}-terraform-access"
  description = "Policy for Terraform to manage resources"

  lifecycle {
    create_before_destroy = true
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "iam:*",
          "logs:*",
          "secretsmanager:*",
          "ssm:*",
          "cloudwatch:*",
          "application-autoscaling:*",
          "autoscaling:*",
          "route53:*",
          "acm:*",
          "ecr:*",
          "ecs:*",
          "kms:*",
          "elasticfilesystem:*",
          "elasticache:*",
          "rds:*",
          "lambda:*",
          "apigateway:*",
          "cloudfront:*",
          "events:*",
          "sns:*",
          "sqs:*",
          "dynamodb:*",
          "tag:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:AllocateAddress",
          "ec2:ImportKeyPair",
          "logs:TagResource",
          "logs:UntagResource",
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "acm:RequestCertificate",
          "acm:DeleteCertificate",
          "acm:ImportCertificate",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.terraform_access.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
