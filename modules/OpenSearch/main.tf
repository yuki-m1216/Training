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
