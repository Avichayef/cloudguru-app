module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  environment          = var.environment
  project_name         = var.project_name
}

module "security" {
  source = "./modules/security"

  vpc_id               = module.vpc.vpc_id
  bastion_allowed_cidr = var.bastion_allowed_cidr
  environment          = var.environment
  project_name         = var.project_name
}

module "bastion" {
  source = "./modules/bastion"

  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  bastion_sg_id         = module.security.bastion_sg_id
  bastion_instance_type = var.bastion_instance_type
  environment           = var.environment
  project_name          = var.project_name
}

module "iam" {
  source = "./modules/iam"

  environment  = var.environment
  project_name = var.project_name
}

module "secrets" {
  source = "./modules/secrets"

  app_secrets  = var.app_secrets
  environment  = var.environment
  project_name = var.project_name
}

module "alb" {
  source = "./modules/alb"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  environment       = var.environment
  project_name      = var.project_name
}

module "ecs" {
  source = "./modules/ecs"

  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_sg_id             = module.security.ecs_sg_id
  execution_role_arn    = module.iam.ecs_execution_role_arn
  task_role_arn         = module.iam.ecs_task_role_arn
  app_container_image   = var.app_container_image
  app_container_port    = var.app_container_port
  app_count             = var.app_count
  fargate_cpu           = var.fargate_cpu
  fargate_memory        = var.fargate_memory
  alb_target_group_arn  = module.alb.target_group_arn
  secrets_manager_arn   = module.secrets.secret_arn
  environment           = var.environment
  project_name          = var.project_name
}
