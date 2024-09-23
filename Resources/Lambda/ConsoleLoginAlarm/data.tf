data "aws_caller_identity" "current" {}

# lambda
data "archive_file" "function" {
  type        = "zip"
  source_file = "lambda/dist/index.js"
  output_path = "lambda/upload/source.zip"
}

data "aws_ssm_parameter" "webhookURL" {
  name = "webhookURL"
}

# IAM Policy Document EventBridge Sender
data "aws_iam_policy_document" "EventBridgeSender" {
  statement {
    actions = [
      "events:PutEvents"
    ]
    resources = [module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]]
  }
}
