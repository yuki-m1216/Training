locals {
  create_policies_for_kinesis = {
    CWL-To-S3-Kinesis-Policy = data.aws_iam_policy_document.kinesis.json
  }
  create_policies_for_subscription_filter = {
    Subscription-Filter-for-Kinesis-Policy = data.aws_iam_policy_document.subscription_filter.json
  }
}
