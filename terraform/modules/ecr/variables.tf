# ECR Module Variables

variable "repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
