output "collection_endpoint" {
  value = module.OpenSearchServerless.collection.collection_endpoint
}

output "opensearch_access_role_id" {
  value = aws_iam_role.opensearch_access_role.id
}

output "opensearch_access_role_arn" {
  value = aws_iam_role.opensearch_access_role.arn
}