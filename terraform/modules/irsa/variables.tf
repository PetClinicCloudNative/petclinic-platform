variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the ServiceAccount"
  type        = string
}

variable "service_account" {
  description = "Kubernetes ServiceAccount name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL without https:// prefix"
  type        = string
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
