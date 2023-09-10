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

    cloudwatch_logging_options_enabled         = true
    cloudwatch_logging_options_log_group_name  = module.cwl_for_kinesis.cwl_logs_group_name
    cloudwatch_logging_options_log_stream_name = module.cwl_for_kinesis.cwl_logs_stream_name
  }]
}

module "iam_for_kinesis" {
  source = "../../../modules/IAM/Role/"

  role_name                  = "CWL-To-S3-Kinesis-Role"
  trusted_entity_aws_service = true
  identifiers                = "firehose.amazonaws.com"
  create_policies            = local.create_policies_for_kinesis
}

module "s3_bucket_for_kinesis" {
  source = "../../../modules/S3"

  # bucket
  bucket_name = "cwl-to-s3-kinesis-s3"
}

module "cwl_for_kinesis" {
  source = "../../../modules/CloudWatch/Logs/"

  # logs
  log_group_name              = "/aws/kinesisfirehose/CWL-To-S3-Kinesis"
  log_group_retention_in_days = 7
  # stream
  create_log_stream = true
  log_stream_name   = "DestinationDelivery"
}

module "cwl_for_test" {
  source = "../../../modules/CloudWatch/Logs/"

  # logs
  log_group_name              = "CWL-To-S3-Kinesis-Test"
  log_group_retention_in_days = 7
  # stream
  create_log_stream = true
  log_stream_name   = "Test-strem"
  # subscription filter
  create_subscription_filter   = true
  subscription_filter_name     = "filter for kinesis"
  subscription_filter_role_arn = module.iam_for_subscription_filter.role_arn
  filter_pattern               = ""
  destination_arn              = module.kinesis.kinesis_firehose_delivery_stream_arn
}

module "iam_for_subscription_filter" {
  source = "../../../modules/IAM/Role/"

  role_name                  = "Subscription-Filter-for-Kinesis-Role"
  trusted_entity_aws_service = true
  identifiers                = "logs.${data.aws_region.current.name}.amazonaws.com"
  create_policies            = local.create_policies_for_subscription_filter
}
