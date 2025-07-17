terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "test-terraform-state-bucket-mohit"
    key            = "shared-infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "test-terraform-state-locks-mohit"
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "main" {
  name = var.domain_name
}

# Shared VPC
module "vpc" {
  source = "../modules/shared-vpc"

  name_prefix        = "mercor-shared"
  cidr_block         = "10.0.0.0/16"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = local.common_tags
}

# Shared ALB
module "alb" {
  source = "../modules/shared-alb"

  name_prefix    = "mercor-shared"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  domain_name    = var.domain_name
  hosted_zone_id = data.aws_route53_zone.main.zone_id

  tags = local.common_tags
}

# Shared ECS Cluster
module "ecs_cluster" {
  source = "../modules/shared-ecs"

  name_prefix     = "mercor-shared"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  tags = local.common_tags
}

# Shared EFS for MongoDB storage
module "efs" {
  source = "../modules/shared-efs"

  name_prefix     = "mercor-shared"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  tags = local.common_tags
}

locals {
  common_tags = {
    Environment = "shared"
    Project     = "mercor-pr-deployments"
    ManagedBy   = "terraform"
  }
}