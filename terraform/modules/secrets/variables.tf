# PETPLAT-33: Secrets module variables

variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "openai_api_key" {
  description = "OpenAI API key value to store in Secrets Manager"
  type        = string
  sensitive   = true
}

variable "git_username" {
  description = "Git username for Config Server (optional, null = skip creation)"
  type        = string
  default     = null
  sensitive   = true
}

variable "git_password" {
  description = "Git password for Config Server (optional, null = skip creation)"
  type        = string
  default     = null
  sensitive   = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
