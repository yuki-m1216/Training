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

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "mylogs.s3.amazonaws.com"
    prefix          = "myprefix"
  }

  aliases = ["mysite.example.com", "yoursite.example.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
