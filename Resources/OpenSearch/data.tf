# data resource kms es
data "aws_kms_key" "alias_es" {
  key_id = "alias/aws/es"
}

data "aws_caller_identity" "current" {}

data "http" "checkip" {
  url = "http://ipv4.icanhazip.com/"
}

data "aws_iam_policy_document" "access_policies" {
  statement {
    sid    = "TestAccess"
    effect = "Allow"
    # principals {
    #   type        = "AWS"
    #   identifiers = ["${data.aws_caller_identity.current.arn}"]
    # }
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["${local.current-ip}/32"]
    }
    actions = [
      "es:*"
    ]
    resources = ["${module.opensearch.opensearch_arn}/*"]
  }
}
