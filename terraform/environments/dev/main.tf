# PETPLAT-5: Dev environment root module
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# PETPLAT-9: Wire VPC module into dev environment
module "vpc" {
  source              = "../../modules/vpc"
  project             = var.project
  environment         = var.environment
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zones  = ["eu-central-1a", "eu-central-1b"]
  tags                = local.common_tags
}

# PETPLAT-15: Wire EKS module into dev environment
module "eks" {
  source                     = "../../modules/eks"
  project                    = var.project
  environment                = var.environment
  cluster_name               = "${var.project}-${var.environment}"
  subnet_ids                 = module.vpc.subnet_ids
  cluster_security_group_ids = [module.vpc.eks_cluster_sg_id]
  tags                       = local.common_tags
  node_group_name            = "${var.project}-${var.environment}-nodes"
  node_instance_types        = ["t4g.small"]
  node_min_size              = 2
  node_max_size              = 4
  node_desired_size          = 2
}

# PETPLAT-20: Wire ECR module into dev environment
module "ecr" {
  source               = "../../modules/ecr"
  project              = var.project
  environment          = var.environment
  service_names        = [
    "config-server",
    "discovery-server",
    "api-gateway",
    "customers-service",
    "visits-service",
    "vets-service",
    "genai-service",
    "admin-server",
  ]
  image_tag_mutability = "MUTABLE"
  tags                 = local.common_tags
}

# PETPLAT-25: Wire RDS module into dev environment
module "rds" {
  source                  = "../../modules/rds"
  project                 = var.project
  environment             = var.environment
  subnet_ids              = module.vpc.subnet_ids
  rds_security_group_id   = module.vpc.rds_sg_id
  instance_class          = "db.t4g.micro"
  multi_az                = false
  skip_final_snapshot     = true
  backup_retention_period = 7
  tags                    = local.common_tags
}
