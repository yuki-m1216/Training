# logs
output "cwl_logs_group_arn" {
  value = aws_cloudwatch_log_group.main.arn
}

output "cwl_logs_group_name" {
  value = aws_cloudwatch_log_group.main.name
}

# stream
output "cwl_logs_stream_arn" {
  value = try(aws_cloudwatch_log_stream.main[0].arn, null)
}

output "cwl_logs_stream_name" {
  value = try(aws_cloudwatch_log_stream.main[0].name, null)
}
