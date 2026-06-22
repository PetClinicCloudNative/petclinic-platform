# PETPLAT-28: DNS module variables

variable "domain_name" {
  description = "Root domain for the hosted zone (e.g., cloud.buildwithmanish.online)"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
