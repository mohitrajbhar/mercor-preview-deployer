output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "cluster_id" {
  description = "ECS cluster ID"
  value       = module.ecs_cluster.cluster_id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs_cluster.cluster_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.alb.alb_arn
}

output "alb_listener_arn" {
  description = "ALB HTTPS listener ARN"
  value       = module.alb.listener_arn
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.alb.security_group_id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = module.alb.alb_zone_id
}

output "efs_id" {
  description = "EFS file system ID"
  value       = module.efs.file_system_id
}

output "efs_security_group_id" {
  description = "EFS security group ID"
  value       = module.efs.security_group_id
}

output "execution_role_arn" {
  description = "ECS execution role ARN"
  value       = module.ecs_cluster.execution_role_arn
}

output "task_role_arn" {
  description = "ECS task role ARN"
  value       = module.ecs_cluster.task_role_arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = module.alb.alb_zone_id
}

output "efs_id" {
  description = "EFS file system ID"
  value       = module.efs.file_system_id
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}