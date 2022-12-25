# cloudfront
module "cloudfront" {
  source = "../../../modules/CloudFront"

  # distribution
  origin = [{
    domain_name              = module.origin_s3.s3_bucket.bucket_domain_name
    origin_access_control_id = null
    origin_id                = module.origin_s3.s3_bucket.arn
    origin_path              = null
    custom_origin_config     = null
    custom_header            = null
    origin_shield            = null
    connection_attempts      = 3
    connection_timeout       = 10
    }
  ]

  default_cache_behavior = [{
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    target_origin_id           = module.origin_s3.s3_bucket.arn
    cache_policy_id            = null
    origin_request_policy_id   = null
    response_headers_policy_id = null
  }]

  viewer_certificate = [{
    cloudfront_default_certificate = true
    acm_certificate_arn            = null
    minimum_protocol_version       = null
    ssl_support_method             = null
  }]

  # oac
  oac_create  = true
  oac_name    = "CloudFront-OAC"
  description = "test CloudFront-OAC"
}


# S3
module "origin_s3" {
  source = "../../../modules/S3"

  # bucket
  bucket_name = "test-ymitsuyama-origin-s3bucket"

  # ownership_controls
  object_ownership = "BucketOwnerPreferred"

  # versionings
  versioning_status = "Enabled"

  # # lifecycle_configuration
  # lifecycle_configuration = true
  # lifecycle_rules = [{
  #   id     = "test-id"
  #   status = "Enabled"
  #   prefix = ""

  #   expiration = [{
  #     days                         = 30
  #     date                         = null
  #     expired_object_delete_marker = null
  #   }]

  #   transition = []

  #   noncurrent_version_expiration = [{
  #     noncurrent_days           = 30
  #     newer_noncurrent_versions = 1
  #   }]

  #   noncurrent_version_transition = []
  # }]

  # s3_bucket_policy
  create_bucket_policy   = true
  bucket_policy_document = data.aws_iam_policy_document.static-www.json
}

data "aws_iam_policy_document" "static-www" {
  statement {
    sid    = "Allow CloudFront"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${module.origin_s3.s3_bucket.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [module.cloudfront.cloudfront_arn]
    }
  }
}
