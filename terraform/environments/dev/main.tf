provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment this block to enable remote state
  # backend "s3" {
  #   bucket         = "terraform-state-cloudguru-app"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  environment          = var.environment
  project_name         = var.project_name
}

module "security" {
  source = "../../modules/security"

  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = var.vpc_cidr
  allowed_cidr_blocks  = var.allowed_cidr_blocks
  bastion_allowed_cidr = var.bastion_allowed_cidr
  app_container_port   = var.app_container_port
  environment          = var.environment
  project_name         = var.project_name
}

module "bastion" {
  source = "../../modules/bastion"

  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  bastion_sg_id         = module.security.bastion_sg_id
  bastion_instance_type = var.bastion_instance_type
  ssh_public_key        = var.ssh_public_key
  environment           = var.environment
  project_name          = var.project_name
}

module "iam" {
  source = "../../modules/iam"

  environment  = var.environment
  project_name = var.project_name
}

module "secrets" {
  source = "../../modules/secrets"

  app_secrets  = var.app_secrets
  environment  = var.environment
  project_name = var.project_name
}

module "alb" {
  source = "../../modules/alb"

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  app_container_port = var.app_container_port
  health_check_path  = var.health_check_path
  environment        = var.environment
  project_name       = var.project_name
}

module "ecs" {
  source = "../../modules/ecs"

  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  ecs_sg_id               = module.security.ecs_sg_id
  execution_role_arn      = module.iam.ecs_execution_role_arn
  task_role_arn           = module.iam.ecs_task_role_arn
  backend_container_image = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/microservices/backend:latest"
  proxy_container_image   = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/microservices/proxy:latest"
  app_container_port      = var.app_container_port
  app_count               = var.app_count
  fargate_cpu             = var.fargate_cpu
  fargate_memory          = var.fargate_memory
  lb_listener             = module.alb.https_listener
  alb_target_group_arn    = module.alb.target_group_arn
  secrets_manager_arn     = module.secrets.secret_arn
  container_secrets       = var.app_secrets
  aws_region              = var.aws_region
  environment             = var.environment
  project_name            = var.project_name
}
