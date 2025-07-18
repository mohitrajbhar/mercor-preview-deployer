variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "preview-url.trial.mercor.com"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate to use"
  type        = string
}
