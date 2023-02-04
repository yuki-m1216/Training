output "dynamodb_table_arn" {
  value = aws_dynamodb_table.dynamodb_table.arn
}

output "dynamodb_table_id" {
  value = aws_dynamodb_table.dynamodb_table.id
}


output "dynamodb_table_hash_key" {
  value = aws_dynamodb_table.dynamodb_table.hash_key
}

output "dynamodb_table_range_key" {
  value = aws_dynamodb_table.dynamodb_table.range_key
}
