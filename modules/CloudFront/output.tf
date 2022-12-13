output "cloudfront_id" {
  value = aws_cloudfront_distribution.distribution.id
}

output "cloudfront_arn" {
  value = aws_cloudfront_distribution.distribution.arn
}
