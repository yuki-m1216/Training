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
      enabled                        = advanced_security_option.value.enabled
      anonymous_auth_enabled         = true
      internal_user_database_enabled = advanced_security_option.value.internal_user_database_enabled
      master_user_options {
        master_user_name     = advanced_security_option.value.internal_user_database_enabled ? advanced_security_option.value.master_user_name : null
        master_user_password = advanced_security_option.value.internal_user_database_enabled ? advanced_security_option.value.master_user_password : null
        master_user_arn      = advanced_security_option.value.internal_user_database_enabled ? null : advanced_security_option.value.master_user_arn
      }
    }
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.kms_key_id
  }

  node_to_node_encryption {
    enabled = true
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
