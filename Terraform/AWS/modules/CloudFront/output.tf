output "cloudfront_id" {
  value = aws_cloudfront_distribution.distribution.id
}

output "cloudfront_arn" {
  value = aws_cloudfront_distribution.distribution.arn
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.distribution.domain_name
}

output "cloudfront_hosted_zone_id" {
  value = aws_cloudfront_distribution.distribution.hosted_zone_id
}
