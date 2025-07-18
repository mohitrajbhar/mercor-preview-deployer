variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "pr_number" {
  description = "PR number for resource naming"
  type        = string
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "preview-url.trial.mercor.com"
}

variable "django_image" {
  description = "Django Docker image"
  type        = string
}

variable "mongodb_image" {
  description = "MongoDB Docker image"
  type        = string
  default     = "mongo:7.0"
}