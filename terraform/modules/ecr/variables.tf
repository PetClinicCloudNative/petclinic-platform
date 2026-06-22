# PETPLAT-18: ECR module variables

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "service_names" {
  description = "List of microservice names to create ECR repositories for"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# PETPLAT-19: Tag mutability configuration
variable "image_tag_mutability" {
  description = "Tag mutability for ECR repositories: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"
}
