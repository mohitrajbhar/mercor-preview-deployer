output "deployment_url" {
  description = "Deployment URL"
  value       = module.pr_services.deployment_url
}

output "django_service_name" {
  description = "Django service name"
  value       = module.pr_services.django_service_name
}

output "mongodb_service_name" {
  description = "MongoDB service name"
  value       = module.pr_services.mongodb_service_name
}