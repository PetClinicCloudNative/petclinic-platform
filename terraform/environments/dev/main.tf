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

# Supplementary rule: EKS managed node group uses auto-created SG instead of
# VPC module eks_node SG. Allow VPC CIDR access to RDS for connectivity.
resource "aws_security_group_rule" "rds_vpc_ingress" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = module.vpc.rds_sg_id
}

# PETPLAT-29: IAM policy for AWS Load Balancer Controller
resource "aws_iam_policy" "lb_controller" {
  name   = "${var.project}-${var.environment}-lb-controller-policy"
  policy = file("${path.module}/../../policies/aws-load-balancer-controller-policy.json")
  tags   = local.common_tags
}

# PETPLAT-29: IRSA role for AWS Load Balancer Controller
module "lb_controller_irsa" {
  source            = "../../modules/irsa"
  role_name         = "${var.project}-${var.environment}-lb-controller-role"
  namespace         = "kube-system"
  service_account   = "aws-load-balancer-controller"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  policy_arns       = [aws_iam_policy.lb_controller.arn]
  tags              = local.common_tags
}

# PETPLAT-37: IAM policy for External Secrets Operator
resource "aws_iam_policy" "external_secrets" {
  name   = "${var.project}-${var.environment}-external-secrets-policy"
  policy = file("${path.module}/../../policies/external-secrets-policy.json")
  tags   = local.common_tags
}

# PETPLAT-37: IRSA role for External Secrets Operator
module "external_secrets_irsa" {
  source            = "../../modules/irsa"
  role_name         = "${var.project}-${var.environment}-external-secrets-role"
  namespace         = "external-secrets"
  service_account   = "external-secrets"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  policy_arns       = [aws_iam_policy.external_secrets.arn]
  tags              = local.common_tags
}

# PETPLAT-32: Wire DNS module into dev environment
module "dns" {
  source      = "../../modules/dns"
  domain_name = "cloud.buildwithmanish.online"
  tags        = local.common_tags
}

# PETPLAT-33: Wire Secrets module into dev environment
module "secrets" {
  source         = "../../modules/secrets"
  project        = var.project
  environment    = var.environment
  openai_api_key = var.openai_api_key
  git_username   = var.git_username
  git_password   = var.git_password
  tags           = local.common_tags
}
