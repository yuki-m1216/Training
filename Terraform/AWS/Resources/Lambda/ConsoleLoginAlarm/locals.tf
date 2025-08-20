# IAM Role Lambda
locals {
  Lambdapolicies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

# IAM Role EventBridge Sender
locals {
  create_policies = {
    "EventBridgeSenderPolicy" = data.aws_iam_policy_document.EventBridgeSender.json,
  }

  # EventBridgeSenderpolicies = [
  #   "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/EventBridgeSenderPolicy"
  # ]

}
