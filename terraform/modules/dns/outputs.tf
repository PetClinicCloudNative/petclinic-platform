# PETPLAT-28: DNS module outputs

output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "zone_name_servers" {
  description = "Name servers for the hosted zone"
  value       = aws_route53_zone.main.name_servers
}

output "certificate_arn" {
  description = "ARN of the validated ACM wildcard certificate"
  value       = aws_acm_certificate_validation.main.certificate_arn
}
