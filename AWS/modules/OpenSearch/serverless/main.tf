resource "aws_opensearchserverless_security_policy" "this" {
  name = var.security_poloicy_name
  type = var.security_policy_type
  description = var.security_policy_description
  policy = var.security_policy
}

resource "aws_opensearchserverless_access_policy" "this" {
  name = var.access_plicy_name
  type = "data"
  description = var.access_policy_description
  policy = var.access_policy
}

resource "aws_opensearchserverless_collection" "this" {
  name = var.collection_name
  description = var.collection_description
  type = var.collection_type
  standby_replicas = var.standby_replicas
  tags = var.collection_tags
  }