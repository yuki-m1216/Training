# cloudfront
module "opensearch" {
  source = "../../modules/OpenSearch"

  # opensearch
  domain_name    = "test-domain"
  engine_version = "OpenSearch_2.3"
  ebs_enabled    = true
  kms_key_id     = data.aws_kms_key.alias_es.id
  advanced_security_options = [{
    enabled                        = true
    internal_user_database_enabled = true
    master_user_name               = "test-user"
    master_user_password           = random_password.password.result
    master_user_arn                = null
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
  key_id      = data.aws_kms_key.alias_es.id
  value       = random_password.password.result

  tags = {
    Name = "/example/opensearch/password/master"
  }
}

# random password
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
