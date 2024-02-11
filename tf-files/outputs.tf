output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "alb_dns_name" {
  value = "http://${aws_alb.app_lb.dns_name}"
}

output "cf_dns_name" {
  value = "http://${aws_cloudfront_distribution.alb_cf_distro.domain_name}"
}

output "websiteurl" {
  value = "http://${aws_route53_record.primary.name}"
}