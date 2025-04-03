#!/bin/bash
set -e

# Set variables
PROJECT_NAME=${1:-cloudguru-app}
ENVIRONMENT=${2:-dev}
REGION=${3:-us-east-1}

echo "Cleaning up resources for $PROJECT_NAME-$ENVIRONMENT in $REGION..."

# Function to delete a resource and ignore errors if it doesn't exist
delete_resource() {
  local resource_type=$1
  local resource_id=$2
  local extra_args=$3

  echo "Attempting to delete $resource_type: $resource_id"
  aws $resource_type delete-$resource_id $extra_args || echo "Resource not found or already deleted"
}

# Create OIDC provider if it doesn't exist
echo "Creating OIDC provider if it doesn't exist..."
OIDC_PROVIDER_ARN=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" --output text)

if [ -z "$OIDC_PROVIDER_ARN" ]; then
  echo "Creating OIDC provider..."
  OIDC_PROVIDER_ARN=$(aws iam create-open-id-connect-provider \
    --url "https://token.actions.githubusercontent.com" \
    --client-id-list "sts.amazonaws.com" \
    --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" \
    --query "OpenIDConnectProviderArn" --output text) || echo "Failed to create OIDC provider"
  echo "Created OIDC provider: $OIDC_PROVIDER_ARN"
fi

# Create initial GitHub Actions role with admin permissions if it doesn't exist
echo "Creating initial GitHub Actions role if it doesn't exist..."
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
          "token.actions.githubusercontent.com:sub": "repo:Avichayef/cloudguru-app:*"
        }
      }
    }
  ]
}
EOF

  # Create role
  aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file:///tmp/trust-policy.json || echo "Failed to create role"

  # Attach AdministratorAccess policy to the role
  aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess || echo "Failed to attach policy"

  echo "Created role $ROLE_NAME with AdministratorAccess"
fi

# Delete IAM policies
echo "Deleting IAM policies..."
for policy_name in "$PROJECT_NAME-$ENVIRONMENT-terraform-access" "$PROJECT_NAME-$ENVIRONMENT-secrets-manager-access" "$PROJECT_NAME-$ENVIRONMENT-ecs-task-policy"; do
  policy_arn=$(aws iam list-policies --query "Policies[?PolicyName=='$policy_name'].Arn" --output text || echo "")
  if [ ! -z "$policy_arn" ]; then
    # Detach policy from all roles
    for role in $(aws iam list-entities-for-policy --policy-arn $policy_arn --query "PolicyRoles[].RoleName" --output text || echo ""); do
      echo "Detaching policy $policy_name from role $role"
      aws iam detach-role-policy --role-name $role --policy-arn $policy_arn || echo "Failed to detach policy"
    done

    # Delete policy
    echo "Deleting policy $policy_name"
    aws iam delete-policy --policy-arn $policy_arn || echo "Failed to delete policy"
  fi
done

# Delete IAM roles
echo "Deleting IAM roles..."
for role_name in "$PROJECT_NAME-$ENVIRONMENT-github-actions-role" "$PROJECT_NAME-$ENVIRONMENT-ecs-execution-role" "$PROJECT_NAME-$ENVIRONMENT-ecs-task-role"; do
  # Check if role exists
  if aws iam get-role --role-name $role_name >/dev/null 2>&1; then
    # Detach all policies
    for policy_arn in $(aws iam list-attached-role-policies --role-name $role_name --query "AttachedPolicies[].PolicyArn" --output text || echo ""); do
      echo "Detaching policy $policy_arn from role $role_name"
      aws iam detach-role-policy --role-name $role_name --policy-arn $policy_arn || echo "Failed to detach policy"
    done

    # Delete role
    echo "Deleting role $role_name"
    aws iam delete-role --role-name $role_name || echo "Failed to delete role"
  fi
done

# Delete CloudWatch log group
echo "Deleting CloudWatch log group..."
aws logs delete-log-group --log-group-name "/ecs/$PROJECT_NAME-$ENVIRONMENT" || echo "Log group not found or already deleted"

# Delete ALB target group
echo "Deleting ALB target group..."
tg_arn=$(aws elbv2 describe-target-groups --names "$PROJECT_NAME-$ENVIRONMENT-tg" --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null || echo "")
if [ ! -z "$tg_arn" ] && [ "$tg_arn" != "None" ]; then
  echo "Deleting target group $tg_arn"
  aws elbv2 delete-target-group --target-group-arn $tg_arn || echo "Failed to delete target group"
fi

# Delete ACM certificate
echo "Deleting ACM certificate..."
cert_arn=$(aws acm list-certificates --query "CertificateSummaryList[?contains(DomainName, '$PROJECT_NAME-$ENVIRONMENT')].CertificateArn" --output text || echo "")
if [ ! -z "$cert_arn" ] && [ "$cert_arn" != "None" ]; then
  echo "Deleting certificate $cert_arn"
  aws acm delete-certificate --certificate-arn $cert_arn || echo "Failed to delete certificate"
fi

echo "Cleanup completed!"
