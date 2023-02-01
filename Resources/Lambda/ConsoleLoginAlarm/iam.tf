# IAM Role Lambda
module "IAM_Role_Lambda" {
  source      = "../../../modules/IAM/Role"
  role_name   = "ConsoleLoginAlarmLambdaRole"
  identifiers = "lambda.amazonaws.com"
  policies    = local.Lambdapolicies
}

# IAM Role EventBridge Sender
module "IAM_Role_EventBridge_Sender" {
  source          = "../../../modules/IAM/Role"
  role_name       = "ConsoleLoginAlarmEventBridgeSenderRole"
  identifiers     = "events.amazonaws.com"
  create_policies = local.create_policies
  # policies        = local.EventBridgeSenderpolicies
}
