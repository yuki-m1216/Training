variable "kinesis_firehose_name" {
  type        = string
  description = "A name to identify the stream."
}

variable "kinesis_firehose_destination" {
  type        = string
  description = "This is the destination to where the data is delivered."
}

variable "extended_s3_configuration" {
  type = list(object({
    role_arn            = string
    bucket_arn          = string
    prefix              = string
    error_output_prefix = string
    buffering_size      = number
    buffering_interval  = number
    compression_format  = string
    kms_key_arn         = string

    cloudwatch_logging_options_enabled         = bool
    cloudwatch_logging_options_log_group_name  = string
    cloudwatch_logging_options_log_stream_name = string
  }))
  description = "The S3 Configuration."
  default     = null
}
