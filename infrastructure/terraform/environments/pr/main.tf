terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "test-terraform-state-bucket-mohit-trial-1"
    key            = "pr-environments/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "test-terraform-state-locks-mohit-trial"
  }
}

provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket         = "test-terraform-state-bucket-mohit-trial-1"
    key            = "shared-infrastructure/terraform.tfstate"
    region         = var.aws_region
    encrypt        = true
    dynamodb_table = "test-terraform-state-locks-mohit-trial"
  }
}

data "aws_route53_zone" "main" {
  name = var.domain_name
}

# Deploy PR-specific. services
module "pr_services" {
  source = "../../modules/pr-services"

  pr_number             = var.pr_number
  vpc_id                = data.terraform_remote_state.shared.outputs.vpc_id
  private_subnets       = data.terraform_remote_state.shared.outputs.private_subnets
  cluster_id            = data.terraform_remote_state.shared.outputs.cluster_id
  alb_listener_arn      = data.terraform_remote_state.shared.outputs.alb_listener_arn
  alb_security_group_id = data.terraform_remote_state.shared.outputs.alb_security_group_id
  alb_dns_name          = data.terraform_remote_state.shared.outputs.alb_dns_name
  alb_zone_id           = data.terraform_remote_state.shared.outputs.alb_zone_id
  efs_id                = data.terraform_remote_state.shared.outputs.efs_id
  efs_security_group_id = data.terraform_remote_state.shared.outputs.efs_security_group_id
  execution_role_arn    = data.terraform_remote_state.shared.outputs.execution_role_arn
  task_role_arn         = data.terraform_remote_state.shared.outputs.task_role_arn
  hosted_zone_id        = data.aws_route53_zone.main.zone_id
  domain_name           = var.domain_name

  django_image  = var.django_image
  mongodb_image = var.mongodb_image

  tags = local.common_tags
}

locals {
  common_tags = {
    Environment = "pr-${var.pr_number}"
    PR_Number   = var.pr_number
    Project     = "mercor-pr-deployment"
    ManagedBy   = "terraform"
  }
}