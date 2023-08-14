data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = var.private_zone
}
