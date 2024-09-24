# iam policy
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
      variable = "AWS:SourceArn"
      values   = [module.cloudfront.cloudfront_arn]
    }
  }
}

# route53 zone
data "aws_route53_zone" "main" {
  name         = "yuki-m.com"
  private_zone = false
}

# acm
data "terraform_remote_state" "acm_us_east_1" {
  backend = "s3"

  config = {
    bucket = "s3-terraform-state-y-mitsuyama"
    key    = "ACM.tfstate"
    region = "ap-northeast-1"
  }
}
