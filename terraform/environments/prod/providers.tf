# PETPLAT-5: AWS provider configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
