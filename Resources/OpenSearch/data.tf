# data resource kms es
data "aws_kms_key" "alias_es" {
  key_id = "alias/aws/es"
}

# data resource kms ssm
data "aws_kms_key" "alias_ssm" {
  key_id = "alias/aws/ssm"
}


data "aws_caller_identity" "current" {}

data "http" "checkip" {
  url = "http://ipv4.icanhazip.com/"
}

data "aws_iam_policy_document" "access_policies" {
  statement {
    sid    = "TestAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["${module.cognito.authenticated_iam_role_arn}"]
    }
    # principals {
    #   type        = "*"
    #   identifiers = ["*"]
    # }

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

# data "aws_iam_policy_document" "opensearch_access_policy" {
#   version = "2012-10-17"
#   statement {
#     effect = "Allow"
#     principals {
#       type        = "AWS"
#       identifiers = ["${lookup(module.cognito.cognito_map, "auth_arn")}"]
#     }
#     actions   = ["es:*"]
#     resources = ["arn:aws:es:${var.region}:${var.account_id}:domain/${var.elasticsearch_domain_name}/*"]
#   }
# }



### open search cognito_options iam ###
# https://docs.aws.amazon.com/ja_jp/opensearch-service/latest/developerguide/cognito-auth.html
data "aws_iam_policy_document" "cognito_opensearch_policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "cognito-idp:DescribeUserPool",
      "cognito-idp:CreateUserPoolClient",
      "cognito-idp:DeleteUserPoolClient",
      "cognito-idp:DescribeUserPoolClient",
      "cognito-idp:AdminInitiateAuth",
      "cognito-idp:AdminUserGlobalSignOut",
      "cognito-idp:ListUserPoolClients",
      "cognito-identity:DescribeIdentityPool",
      "cognito-identity:UpdateIdentityPool",
      "cognito-identity:SetIdentityPoolRoles",
      "cognito-identity:GetIdentityPoolRoles"
    ]
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "opensearch_assume_policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["opensearchservice.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
