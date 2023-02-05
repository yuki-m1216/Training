output "dynamodb_table_arn" {
  value = var.autoscaling_enable ? aws_dynamodb_table.dynamodb_table_autoscaling[0].arn : aws_dynamodb_table.dynamodb_table[0].arn
}

output "dynamodb_table_id" {
  value = var.autoscaling_enable ? aws_dynamodb_table.dynamodb_table_autoscaling[0].id : aws_dynamodb_table.dynamodb_table[0].id
}


output "dynamodb_table_hash_key" {
  value = var.autoscaling_enable ? aws_dynamodb_table.dynamodb_table_autoscaling[0].hash_key : aws_dynamodb_table.dynamodb_table[0].hash_key
}

output "dynamodb_table_range_key" {
  value = var.autoscaling_enable ? aws_dynamodb_table.dynamodb_table_autoscaling[0].range_key : aws_dynamodb_table.dynamodb_table[0].range_key
}
