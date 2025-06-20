# This Terraform configuration file sets up the infrastructure for an analytical and reporting application on AWS.  
# It uses modules to organize resources such as VPC, ECS Cluster, RDS, ALB, and ECS Services for both the analytical and reporting applications. 
# The configuration is designed to be modular and reusable, allowing for easy adjustments and scaling. 
# The file is written in Terraform 0.14.0 and is compatible with AWS. 
# It uses the AWS provider to create and manage AWS resources.
provider "aws" {
  region = var.aws_region
}

# Root Module: main.tf
# This file orchestrates the deployment of the entire infrastructure using modules.
# --- 1. VPC Module ---
module "vpc" {
  source        = "./modules/vpc"
  project_name  = var.project_name
  environment   = var.environment
  aws_region    = var.aws_region
  nat_gateway_count = 1 # Consistent with CDK nat_gateways=1
}

# --- 2. ECS Cluster Module ---
module "ecs_cluster" {
  source        = "./modules/ecs_cluster"
  project_name  = var.project_name
  environment   = var.environment
  vpc_id        = module.vpc.vpc_id
}

# --- 3. RDS Module ---
module "rds" {
  source            = "./modules/rds"
  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  is_production     = var.is_production
}

# --- 4. ALB Module ---
module "alb" {
  source       = "./modules/alb"
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

# --- 5. ECS Service Module (Analytical App) ---
module "analytical_app_service" {
  source            = "./modules/ecs_service"
  name              = "analytical-app"
  project_name      = var.project_name
  environment       = var.environment
  cluster_id        = module.ecs_cluster.cluster_id
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_secrets_arn    = module.rds.db_password_secret_arn
  db_host           = module.rds.db_instance_address
  db_port           = module.rds.db_instance_port
  db_name           = module.rds.db_instance_name
  db_username       = module.rds.db_master_username
  aws_region        = var.aws_region
  container_port    = 8000
  image_name        = "analytical-app" # Corresponds to ECR repo name
  alb_listener_arn  = module.alb.alb_listener_arn
  alb_path_patterns = ["/api/*", "/"]
  alb_priority      = 1
  health_check_path = "/" # Assuming a basic health check on the root path
}

# --- 6. ECS Service Module (Reporting App) ---
module "reporting_app_service" {
  source            = "./modules/ecs_service"
  name              = "reporting-app"
  project_name      = var.project_name
  environment       = var.environment
  cluster_id        = module.ecs_cluster.cluster_id
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_secrets_arn    = module.rds.db_password_secret_arn
  db_host           = module.rds.db_instance_address
  db_port           = module.rds.db_instance_port
  db_name           = module.rds.db_instance_name
  db_username       = module.rds.db_master_username
  aws_region        = var.aws_region
  container_port    = 8080
  image_name        = "reporting-app" # Corresponds to ECR repo name
  alb_listener_arn  = module.alb.alb_listener_arn
  alb_path_patterns = ["/reporting", "/reporting/*"]
  alb_priority      = 2
  health_check_path = "/reporting"
}

# --- 7. Security Group Rules (Cross-Module Dependencies) ---
# Allow ECS Services to connect to RDS
resource "aws_security_group_rule" "ecs_to_rds_ingress" {
  description       = "Allow ECS Services to connect to RDS"
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = module.rds.rds_security_group_id
  source_security_group_id = module.analytical_app_service.ecs_security_group_id
}

resource "aws_security_group_rule" "reporting_ecs_to_rds_ingress" {
  description       = "Allow Reporting App ECS Service to connect to RDS"
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = module.rds.rds_security_group_id
  source_security_group_id = module.reporting_app_service.ecs_security_group_id
}

# Allow ALB to ECS Service Ingress (done within ECS Service Module, as TG requires ECS SG)