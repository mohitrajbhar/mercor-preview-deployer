output "deployment_url" {
  description = "Deployment URL"
  value       = "pr-${var.pr_number}.${var.domain_name}"
}

output "django_service_name" {
  description = "Django service name"
  value       = aws_ecs_service.django.name
}

output "mongodb_service_name" {
  description = "MongoDB service name"
  value       = aws_ecs_service.mongodb.name
}

output "target_group_arn" {
  description = "ALB target group ARN"
  value       = aws_lb_target_group.django.arn
}