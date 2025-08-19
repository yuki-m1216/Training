resource "aws_opensearchserverless_security_policy" "encryption" {
  name        = var.encryption_security_policy_name
  type        = "encryption"
  description = var.encryption_security_policy_description
  policy      = var.encryption_security_policy
}

resource "aws_opensearchserverless_security_policy" "network" {
  name        = var.network_security_policy_name
  type        = "network"
  description = var.network_security_policy_description
  policy      = var.network_security_policy
}

resource "aws_opensearchserverless_access_policy" "this" {
  name        = var.access_policy_name
  type        = "data"
  description = var.access_policy_description
  policy      = var.access_policy
}

resource "aws_opensearchserverless_collection" "this" {
  name             = var.collection_name
  description      = var.collection_description
  type             = var.collection_type
  standby_replicas = var.standby_replicas
  tags             = var.collection_tags

  depends_on = [aws_opensearchserverless_security_policy.encryption]
}