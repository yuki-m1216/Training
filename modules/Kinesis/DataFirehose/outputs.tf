output "kinesis_firehose_delivery_stream_arn" {
  value = aws_kinesis_firehose_delivery_stream.main.arn
}

output "kinesis_firehose_delivery_stream_name" {
  value = aws_kinesis_firehose_delivery_stream.main.name
}
