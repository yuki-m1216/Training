# opensearch
resource "aws_opensearch_domain" "opensearch" {
  domain_name    = var.domain_name
  engine_version = var.engine_version

  cluster_config {
    instance_type = var.instance_type
  }

  ebs_options {
    ebs_enabled = var.ebs_enabled
    volume_size = var.ebs_enabled ? var.volume_size : null
  }

  dynamic "advanced_security_options" {
    for_each = var.advanced_security_options == null ? [] : var.advanced_security_options

    content {
      enabled                        = advanced_security_options.value.enabled
      anonymous_auth_enabled         = advanced_security_options.value.anonymous_auth_enabled
      internal_user_database_enabled = advanced_security_options.value.internal_user_database_enabled
      master_user_options {
        master_user_name     = advanced_security_options.value.internal_user_database_enabled ? advanced_security_options.value.master_user_name : null
        master_user_password = advanced_security_options.value.internal_user_database_enabled ? advanced_security_options.value.master_user_password : null
        master_user_arn      = advanced_security_options.value.internal_user_database_enabled ? null : advanced_security_options.value.master_user_arn
      }
    }
  }

  dynamic "cognito_options" {
    for_each = var.cognito_options == null ? [] : var.cognito_options

    content {
      enabled          = cognito_options.value.enabled
      user_pool_id     = cognito_options.value.user_pool_id
      identity_pool_id = cognito_options.value.identity_pool_id
      role_arn         = cognito_options.value.role_arn
    }
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.kms_key_id
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  tags = {
    Name = var.domain_name
  }
}

# domain policy
resource "aws_opensearch_domain_policy" "opensearch" {
  count = var.create_domain_policy ? 1 : 0

  domain_name     = aws_opensearch_domain.opensearch.domain_name
  access_policies = var.access_policies
}
