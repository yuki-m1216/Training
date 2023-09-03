module "kinesis" {
  source = "../../../modules/Kinesis/DataFirehose/"

  kinesis_firehose_name        = "CWL-To-S3-Kinesis"
  kinesis_firehose_destination = "extended_s3"

  extended_s3_configuration = [{
    role_arn            = module.iam_for_kinesis.role_arn
    bucket_arn          = module.s3_bucket_for_kinesis.s3_bucket.arn
    prefix              = "cwl/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"
    buffering_size      = 5
    buffering_interval  = 300
    compression_format  = "GZIP"
    kms_key_arn         = data.aws_kms_key.s3.arn

    cloudwatch_logging_options_enabled         = false
    cloudwatch_logging_options_log_group_name  = null
    cloudwatch_logging_options_log_stream_name = null
  }]
}

module "iam_for_kinesis" {
  source = "../../../modules/IAM/Role/"

  role_name                  = "CWL-To-S3-Kinesis-Role"
  trusted_entity_aws_service = true
  identifiers                = "firehose.amazonaws.com"
  create_policies            = local.create_policies
}

module "s3_bucket_for_kinesis" {
  source = "../../../modules/S3"

  # bucket
  bucket_name = "cwl-to-s3-kinesis-s3"
}
