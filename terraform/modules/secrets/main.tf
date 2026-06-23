# PETPLAT-33: Secrets Manager resources for non-RDS application secrets
# RDS credentials are managed by the RDS module (PETPLAT-23).

locals {
  secret_prefix = "${var.project}/${var.environment}"
}

# ── OpenAI API Key (required) ────────────────────────────────────────────────

resource "aws_secretsmanager_secret" "openai_api_key" {
  name        = "${local.secret_prefix}/openai-api-key"
  description = "OpenAI API key for ${var.project}-${var.environment}"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = var.openai_api_key
}

# ── Config Server Git Username (optional) ────────────────────────────────────

resource "aws_secretsmanager_secret" "git_username" {
  count       = var.git_username != null ? 1 : 0
  name        = "${local.secret_prefix}/config-server/git-username"
  description = "Git username for Config Server in ${var.project}-${var.environment}"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "git_username" {
  count         = var.git_username != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.git_username[0].id
  secret_string = var.git_username
}

# ── Config Server Git Password (optional) ────────────────────────────────────

resource "aws_secretsmanager_secret" "git_password" {
  count       = var.git_password != null ? 1 : 0
  name        = "${local.secret_prefix}/config-server/git-password"
  description = "Git password for Config Server in ${var.project}-${var.environment}"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "git_password" {
  count         = var.git_password != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.git_password[0].id
  secret_string = var.git_password
}
