# cloudfront
module "opensearch" {
  source = "../../modules/OpenSearch"

  domain_name    = "test-domain"
  engine_version = "OpenSearch_2.3"

}
