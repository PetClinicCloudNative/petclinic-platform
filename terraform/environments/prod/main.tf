# PETPLAT-5: Prod environment root module
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# PETPLAT-10: Wire VPC module into prod environment
module "vpc" {
  source              = "../../modules/vpc"
  project             = var.project
  environment         = var.environment
  vpc_cidr            = "10.1.0.0/16"
  public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  availability_zones  = ["eu-central-1a", "eu-central-1b"]
  tags                = local.common_tags
}

# PETPLAT-17: Wire EKS module into prod environment
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
