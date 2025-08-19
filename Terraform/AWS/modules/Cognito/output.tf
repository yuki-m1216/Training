# user_pool
output "user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

# identity_pool
output "identity_pool_id" {
  value = aws_cognito_identity_pool.identity_pool.id
}

# authenticated iam role
output "authenticated_iam_role_arn" {
  value = aws_iam_role.authenticated.arn
}
