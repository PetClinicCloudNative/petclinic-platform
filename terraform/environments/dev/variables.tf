# PETPLAT-5: Dev environment variables
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "petclinic"
}

# PETPLAT-33: Secret values passed via TF_VAR_* environment variables
variable "openai_api_key" {
  description = "OpenAI API key (set via TF_VAR_openai_api_key)"
  type        = string
  sensitive   = true
}

variable "git_username" {
  description = "Config Server Git username (set via TF_VAR_git_username, optional)"
  type        = string
  default     = null
  sensitive   = true
}

variable "git_password" {
  description = "Config Server Git password (set via TF_VAR_git_password, optional)"
  type        = string
  default     = null
  sensitive   = true
}
