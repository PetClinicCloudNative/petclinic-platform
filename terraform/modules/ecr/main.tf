# PETPLAT-18: ECR module — repository resources

locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_ecr_repository" "service" {
  for_each = toset(var.service_names)

  name = "${var.project}-${var.environment}/${each.value}"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}/${each.value}"
  })
}
