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

# Skip OIDC provider and role creation - these should be created manually using the bootstrap.sh script
echo "Skipping OIDC provider and role creation - these should be created manually using the bootstrap.sh script"

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
