variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "infra-dev.devrev-eng.ai"
}