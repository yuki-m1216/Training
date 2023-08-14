# cloudfront
resource "aws_cloudfront_distribution" "distribution" {
  dynamic "origin" {
    for_each = var.origin

    content {
      domain_name = origin.value.domain_name
      # https://qiita.com/HirokiSakonju/items/18e532fcf1461876c4f3
      # https://qiita.com/horietakehiro/items/5f5d9166b26bfb4287dd
      origin_access_control_id = (
        origin.value.custom_origin_config == null ? var.oac_create == false ?
        origin.value.origin_access_control_id : aws_cloudfront_origin_access_control.oac[0].id : null
      )
      origin_id   = origin.value.origin_id
      origin_path = origin.value.origin_path

      # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#custom-origin-config-arguments
      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config == null ? [] : origin.value.custom_origin_config

        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
          origin_keepalive_timeout = custom_origin_config.value.origin_keepalive_timeout
          origin_read_timeout      = custom_origin_config.value.origin_read_timeout
        }
      }

      dynamic "custom_header" {
        for_each = origin.value.custom_header == null ? [] : origin.value.custom_header

        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      dynamic "origin_shield" {
        for_each = origin.value.origin_shield == null ? [] : origin.value.origin_shield

        content {
          enabled              = origin_shield.value.enabled
          origin_shield_region = origin_shield.value.origin_shield_region
        }
      }

      connection_attempts = origin.value.connection_attempts
      connection_timeout  = origin.value.connection_timeout

    }
  }


  aliases             = var.aliases
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  http_version        = var.http_version
  comment             = var.comment
  default_root_object = var.default_root_object

  dynamic "logging_config" {
    for_each = var.logging_config == null ? [] : var.logging_config

    content {
      bucket          = logging_config.value.bucket
      prefix          = logging_config.value.prefix
      include_cookies = logging_config.value.include_cookies
    }
  }

  dynamic "default_cache_behavior" {
    for_each = var.default_cache_behavior

    content {
      compress                   = default_cache_behavior.value.compress
      viewer_protocol_policy     = default_cache_behavior.value.viewer_protocol_policy
      allowed_methods            = default_cache_behavior.value.allowed_methods
      cached_methods             = default_cache_behavior.value.cached_methods
      target_origin_id           = default_cache_behavior.value.target_origin_id
      cache_policy_id            = default_cache_behavior.value.cache_policy_id == null ? data.aws_cloudfront_cache_policy.aws_managed_cachingoptimized.id : default_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = default_cache_behavior.value.origin_request_policy_id == null ? data.aws_cloudfront_origin_request_policy.aws_managed_user_agent_referer_headers.id : default_cache_behavior.value.origin_request_policy_id
      response_headers_policy_id = default_cache_behavior.value.response_headers_policy_id == null ? data.aws_cloudfront_response_headers_policy.aws_managed_security_headers_policy.id : default_cache_behavior.value.response_headers_policy_id
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behavior == null ? [] : var.ordered_cache_behavior

    content {
      path_pattern               = ordered_cache_behavior.value.path_pattern
      compress                   = ordered_cache_behavior.value.compress
      viewer_protocol_policy     = ordered_cache_behavior.value.viewer_protocol_policy
      allowed_methods            = ordered_cache_behavior.value.allowed_methods
      cached_methods             = ordered_cache_behavior.value.cached_methods
      target_origin_id           = ordered_cache_behavior.value.target_origin_id
      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id == null ? data.aws_cloudfront_cache_policy.aws_managed_cachingoptimized.id : default_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = ordered_cache_behavior.value.origin_request_policy_id == null ? data.aws_cloudfront_origin_request_policy.aws_managed_user_agent_referer_headers.id : default_cache_behavior.value.origin_request_policy_id
      response_headers_policy_id = ordered_cache_behavior.value.response_headers_policy_id == null ? data.aws_cloudfront_response_headers_policy.aws_managed_security_headers_policy.id : default_cache_behavior.value.response_headers_policy_id
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.restriction_type
      locations        = var.locations
    }
  }

  price_class = var.price_class

  dynamic "viewer_certificate" {
    for_each = var.viewer_certificate

    content {
      cloudfront_default_certificate = viewer_certificate.value.cloudfront_default_certificate
      acm_certificate_arn            = viewer_certificate.value.acm_certificate_arn
      minimum_protocol_version       = viewer_certificate.value.minimum_protocol_version
      ssl_support_method             = viewer_certificate.value.ssl_support_method
    }

  }

  web_acl_id          = var.web_acl_id
  retain_on_delete    = var.retain_on_delete
  wait_for_deployment = var.wait_for_deployment

  tags = {
    Name = var.tags_name
  }
}

# OAC
resource "aws_cloudfront_origin_access_control" "oac" {
  count = var.oac_create ? 1 : 0

  name                              = var.oac_name
  description                       = var.description
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Route53
resource "aws_route53_record" "record" {
  count = var.create_record ? 1 : 0

  zone_id = var.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
