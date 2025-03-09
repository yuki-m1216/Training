### opensearch ###
module "opensearch" {
  source = "../../../modules/OpenSearch/domain"

  # opensearch
  domain_name    = "test-domain"
  engine_version = "OpenSearch_2.3"
  ebs_enabled    = true
  kms_key_id     = data.aws_kms_key.alias_es.id
  advanced_security_options = [{
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = false
    master_user_name               = null
    master_user_password           = null
    master_user_arn                = module.cognito.authenticated_iam_role_arn
  }]

  cognito_options = [{
    enabled          = true
    user_pool_id     = module.cognito.user_pool_id
    identity_pool_id = module.cognito.identity_pool_id
    role_arn         = aws_iam_role.cognito_opensearch_role.arn
  }]

  # domain policy
  create_domain_policy = true
  access_policies      = data.aws_iam_policy_document.access_policies.json
}

# ssm parameter for masteruser password
resource "aws_ssm_parameter" "secret" {
  name        = "/example/opensearch/password/master"
  description = "Example OpenSearch Password Parameter"
  type        = "SecureString"
  key_id      = data.aws_kms_key.alias_ssm.id
  value       = random_password.password.result

  tags = {
    Name = "/example/opensearch/password/master"
  }
}

# random password
resource "random_password" "password" {
  length           = 16
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

### cognito ###
module "cognito" {
  source = "../../../modules/Cognito"

  # cognito
  user_pool_name        = "test-user-pool"
  user_pool_domain      = "test-kibana"
  identity_pool_name    = "test-identity-pool"
  user_pool_client_name = "test-userpool-client"

  # iam
  authenticated_iam_role_name          = "test-authenticated-role"
  authenticated_iam_role_description   = "test-authenticated-role"
  authenticated_iam_policy_name        = "test-authenticated-policy"
  authenticated_iam_policy_description = "test-authenticated-policy"

  unauthenticated_iam_role_name          = "test-unauthenticated-role"
  unauthenticated_iam_role_description   = "test-unauthenticated-role"
  unauthenticated_iam_policy_name        = "test-unauthenticated-policy"
  unauthenticated_iam_policy_description = "test-unauthenticated-policy"
}

### cognito options iam ### 
resource "aws_iam_policy" "cognito_opensearch_policy" {
  name   = "test-cognito-opensearch-accesspolicy"
  policy = data.aws_iam_policy_document.cognito_opensearch_policy.json
}


resource "aws_iam_role" "cognito_opensearch_role" {
  name               = "test-cognito-opensearch-accessrole"
  assume_role_policy = data.aws_iam_policy_document.opensearch_assume_policy.json

}

resource "aws_iam_role_policy_attachment" "cognito_opensearch_attach" {
  role       = aws_iam_role.cognito_opensearch_role.name
  policy_arn = aws_iam_policy.cognito_opensearch_policy.arn
}
