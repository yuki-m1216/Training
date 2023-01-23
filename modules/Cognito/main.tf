# https://github.com/hendrixroa/terraform-aws-cognito-elasticsearch/blob/master/cognito/cognito.tf
### Cognito ###
# user_pool
resource "aws_cognito_user_pool" "user_pool" {
  name = var.user_pool_name

  auto_verified_attributes = ["email"]
  mfa_configuration        = "OFF"
  username_attributes      = ["email"]

  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  username_configuration {
    case_sensitive = false
  }

  email_configuration {
    # https://docs.aws.amazon.com/ja_jp/cognito/latest/developerguide/user-pool-email.html
    email_sending_account = "COGNITO_DEFAULT"
  }
}

# user_pool_domain
resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = "${var.user_pool_domain}-${random_integer.num.result}"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

/* ユーザープールのOpenSearchアプリクライアントとアイデンティティプールの紐づけは
明示的に行わなくても自動的にやってくれる模様
以下URL先でexternalプロバイダを使用して明示的に依存関係を記述しているが不要だった。念のためURLは残す。
https://stackoverflow.com/questions/73421850/terraform-aws-opensearch-using-cognito-module-circular-problem
*/
# identity_pool
resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = var.identity_pool_name
  allow_unauthenticated_identities = true

  lifecycle { ignore_changes = [cognito_identity_providers] }
}

# random_integer
resource "random_integer" "num" {
  min = 10000
  max = 50000
}

### IAM ###
## authenticated
# iam_role
resource "aws_iam_role" "authenticated" {
  name               = var.authenticated_iam_role_name
  description        = var.authenticated_iam_role_description
  assume_role_policy = data.aws_iam_policy_document.authenticated_assume-role-policy.json

  tags = {
    Name = var.authenticated_iam_role_name
  }
}

# iam_policy
resource "aws_iam_policy" "authenticated" {
  name        = var.authenticated_iam_policy_name
  description = var.authenticated_iam_policy_description
  policy      = data.aws_iam_policy_document.authenticated_iam_policy.json

  tags = {
    Name = var.authenticated_iam_policy_name
  }
}

# role_policy_attachment
resource "aws_iam_role_policy_attachment" "authenticated" {
  role       = aws_iam_role.authenticated.name
  policy_arn = aws_iam_policy.authenticated.arn
}

## unauthenticated
# iam_role
resource "aws_iam_role" "unauthenticated" {
  name               = var.unauthenticated_iam_role_name
  description        = var.unauthenticated_iam_role_description
  assume_role_policy = data.aws_iam_policy_document.unauthenticated_assume-role-policy.json

  tags = {
    Name = var.unauthenticated_iam_role_name
  }
}

# iam_policy
resource "aws_iam_policy" "unauthenticated" {
  name        = var.unauthenticated_iam_policy_name
  description = var.unauthenticated_iam_policy_description
  policy      = data.aws_iam_policy_document.unauthenticated_iam_policy.json

  tags = {
    Name = var.unauthenticated_iam_policy_name
  }
}

# role_policy_attachment
resource "aws_iam_role_policy_attachment" "unauthenticated" {
  role       = aws_iam_role.unauthenticated.name
  policy_arn = aws_iam_policy.unauthenticated.arn
}

# cognito_identity_pool_roles_attachment
resource "aws_cognito_identity_pool_roles_attachment" "identity_pool" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool.id
  roles = {
    "authenticated"   = aws_iam_role.authenticated.arn
    "unauthenticated" = aws_iam_role.unauthenticated.arn
  }
}
