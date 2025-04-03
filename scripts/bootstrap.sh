#!/bin/bash
set -e

# Set variables
PROJECT_NAME=${1:-cloudguru-app}
ENVIRONMENT=${2:-dev}
REGION=${3:-us-east-1}
GITHUB_REPO=${4:-Avichayef/cloudguru-app}

echo "Bootstrapping resources for $PROJECT_NAME-$ENVIRONMENT in $REGION..."

# Create OIDC provider if it doesn't exist
echo "Creating OIDC provider if it doesn't exist..."
OIDC_PROVIDER_ARN=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" --output text)

if [ -z "$OIDC_PROVIDER_ARN" ]; then
  echo "Creating OIDC provider..."
  OIDC_PROVIDER_ARN=$(aws iam create-open-id-connect-provider \
    --url "https://token.actions.githubusercontent.com" \
    --client-id-list "sts.amazonaws.com" \
    --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" \
    --query "OpenIDConnectProviderArn" --output text)
  echo "Created OIDC provider: $OIDC_PROVIDER_ARN"
fi

# Create GitHub Actions role with admin permissions
echo "Creating GitHub Actions role..."
ROLE_NAME="$PROJECT_NAME-$ENVIRONMENT-github-actions-role"
ROLE_EXISTS=$(aws iam get-role --role-name $ROLE_NAME --query "Role.RoleName" --output text 2>/dev/null || echo "")

if [ -z "$ROLE_EXISTS" ]; then
  echo "Creating role $ROLE_NAME..."
  # Create trust policy document
  cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$OIDC_PROVIDER_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:$GITHUB_REPO:*"
        }
      }
    }
  ]
}
EOF

  # Create role
  aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file:///tmp/trust-policy.json

  # Attach AdministratorAccess policy to the role
  aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

  echo "Created role $ROLE_NAME with AdministratorAccess"
else
  echo "Role $ROLE_NAME already exists"
fi

echo "Bootstrap completed!"
echo "OIDC Provider ARN: $OIDC_PROVIDER_ARN"
echo "Role ARN: arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/$ROLE_NAME"
echo ""
echo "Please add the Role ARN as a secret in your GitHub repository with the name AWS_ROLE_ARN"
