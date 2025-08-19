resource "aws_kinesis_firehose_delivery_stream" "main" {
  name        = var.kinesis_firehose_name
  destination = var.kinesis_firehose_destination

  dynamic "extended_s3_configuration" {
    for_each = var.extended_s3_configuration == null ? [] : var.extended_s3_configuration

    content {
      role_arn            = extended_s3_configuration.value.role_arn
      bucket_arn          = extended_s3_configuration.value.bucket_arn
      prefix              = extended_s3_configuration.value.prefix
      error_output_prefix = extended_s3_configuration.value.error_output_prefix
      buffering_size      = extended_s3_configuration.value.buffering_size
      buffering_interval  = extended_s3_configuration.value.buffering_interval
      compression_format  = extended_s3_configuration.value.compression_format
      kms_key_arn         = extended_s3_configuration.value.kms_key_arn
      cloudwatch_logging_options {
        enabled         = extended_s3_configuration.value.cloudwatch_logging_options_enabled
        log_group_name  = extended_s3_configuration.value.cloudwatch_logging_options_log_group_name
        log_stream_name = extended_s3_configuration.value.cloudwatch_logging_options_log_stream_name
      }
    }
  }

  tags = {
    Name = var.kinesis_firehose_name
  }

}
