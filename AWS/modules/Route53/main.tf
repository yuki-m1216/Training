# host zone
resource "aws_route53_zone" "main" {
  count = var.create_hostzone ? 1 : 0

  name          = var.hostzone_name
  force_destroy = var.force_destroy

  tags = {
    Name = var.hostzone_name
  }
}

# record
resource "aws_route53_record" "record" {
  count = var.create_record ? 1 : 0

  zone_id = var.zone_id == null ? try(aws_route53_zone.main[0].zone_id, null) : var.zone_id
  name    = var.record_name
  type    = var.type


  dynamic "alias" {
    for_each = var.alias == null ? [] : var.alias

    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

}
