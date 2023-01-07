# cloudfront
module "opensearch" {
  source = "../../modules/OpenSearch"

  # opensearch
  domain_name    = "test-domain"
  engine_version = "OpenSearch_2.3"
  ebs_enabled    = true

  # domain policy
  create_domain_policy = true
  access_policies      = data.aws_iam_policy_document.access_policies.json
}
