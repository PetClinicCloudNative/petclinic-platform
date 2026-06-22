# PETPLAT-22: RDS module — MySQL instance

locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  db_identifier = "${var.project}-${var.environment}-mysql"
}

# ---------------------------------------------------------------
# DB Subnet Group
# ---------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name        = "${var.project}-${var.environment}-db-subnet-group"
  description = "Subnet group for ${var.project} ${var.environment} RDS"
  subnet_ids  = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-db-subnet-group"
  })
}

# ---------------------------------------------------------------
# DB Parameter Group
# ---------------------------------------------------------------
resource "aws_db_parameter_group" "main" {
  name        = "${var.project}-${var.environment}-mysql-params"
  family      = "mysql${var.engine_version}"
  description = "Custom parameter group for ${var.project} ${var.environment}"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-mysql-params"
  })
}

# ---------------------------------------------------------------
# RDS Instance
# ---------------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier     = local.db_identifier
  engine         = "mysql"
  engine_version = var.engine_version

  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true

  multi_az            = var.multi_az
  publicly_accessible = false

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  username = var.master_username
  password = var.master_password

  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = false

  tags = merge(local.common_tags, {
    Name = local.db_identifier
  })
}
