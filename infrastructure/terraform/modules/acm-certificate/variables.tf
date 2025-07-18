variable "domain_name" {
  description = "The domain name for which to create the certificate"
  type        = string
  default     = "preview-url.trial.mercor.com"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "shared"
    Project     = "mercor-preview-deployer"
    ManagedBy   = "terraform"
  }
}