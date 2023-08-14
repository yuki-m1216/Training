resource "aws_route53_zone" "main" {
  name = var.hostzone_name

  tags = {
    Name = var.hostzone_name
  }
}
