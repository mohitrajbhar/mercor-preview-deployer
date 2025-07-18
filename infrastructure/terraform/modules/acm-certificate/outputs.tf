output "certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = aws_acm_certificate_validation.wildcard.certificate_arn
}

output "certificate_domain_name" {
  description = "The domain name of the certificate"
  value       = aws_acm_certificate.wildcard.domain_name
}

output "certificate_status" {
  description = "The status of the certificate"
  value       = aws_acm_certificate.wildcard.status
}

output "hosted_zone_id" {
  description = "The Route53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}