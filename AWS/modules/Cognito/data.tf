### IAM ###
## authenticated
# assume_role_policy
data "aws_iam_policy_document" "authenticated_assume-role-policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = ["${aws_cognito_identity_pool.identity_pool.id}"]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["authenticated"]
    }
  }
}

# iam_policy
data "aws_iam_policy_document" "authenticated_iam_policy" {
  statement {
    effect = "Allow"

    actions = [
      "mobileanalytics:PutEvents",
      "cognito-sync:*",
      "cognito-identity:*",
    ]

    resources = ["*"]

  }
}

## unauthenticated
# assume_role_policy
data "aws_iam_policy_document" "unauthenticated_assume-role-policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = ["${aws_cognito_identity_pool.identity_pool.id}"]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["unauthenticated"]
    }
  }
}

# iam_policy
data "aws_iam_policy_document" "unauthenticated_iam_policy" {
  statement {
    effect = "Allow"

    actions = [
      "mobileanalytics:PutEvents",
      "cognito-sync:*",
    ]

    resources = ["*"]

  }
}
