# cloud front
resource "aws_cloudfront_distribution" "distribution" {
  dynamic "origin" {
    for_each = var.origin

    content {
      domain_name              = origin.value.domain_name
      origin_access_control_id = origin.value.origin_access_control_id
      origin_id                = origin.value.origin_id
      origin_path              = origin.value.origin_path

      # todo
      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
      }

      # todo
      # # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#custom-origin-config-arguments
      # custom_origin_config {
      #   http_port                = 80
      #   https_port               = 5000
      #   origin_protocol_policy   = "match-viewer"
      #   origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      #   origin_keepalive_timeout = 5
      #   origin_read_timeout      = 60
      # }

      dynamic "custom_header" {
        for_each = origin.value.custom_header == null ? [] : origin.value.custom_header

        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }

        origin_shield {
          enabled              = origin.value.origin_shield_enabled
          origin_shield_region = origin.value.origin_shield_region
        }

        connection_attempts = origin.value.connection_attempts
        connection_timeout  = origin.value.connection_timeout

      }
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
      cache_policy_id            = default_cache_behavior.value.cache_policy_id == null ? data.aws_cloudfront_cache_policy.aws_managed_cachingoptimized : default_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = default_cache_behavior.value.origin_request_policy_id == null ? data.aws_cloudfront_origin_request_policy.aws_managed_user_agent_referer_headers : default_cache_behavior.value.origin_request_policy_id
      response_headers_policy_id = default_cache_behavior.value.response_headers_policy_id == null ? data.aws_cloudfront_response_headers_policy : default_cache_behavior.value.response_headers_policy_id
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
      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id == null ? data.aws_cloudfront_cache_policy.aws_managed_cachingoptimized : default_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = ordered_cache_behavior.value.origin_request_policy_id == null ? data.aws_cloudfront_origin_request_policy.aws_managed_user_agent_referer_headers : default_cache_behavior.value.origin_request_policy_id
      response_headers_policy_id = ordered_cache_behavior.value.response_headers_policy_id == null ? data.aws_cloudfront_response_headers_policy : default_cache_behavior.value.response_headers_policy_id
    }
  }

  dynamic "restrictions" {
    for_each = var.restrictions == null ? [] : var.restrictions
    geo_restriction {
      restriction_type = restrictions.value.restriction_type
      locations        = restrictions.value.locations
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
