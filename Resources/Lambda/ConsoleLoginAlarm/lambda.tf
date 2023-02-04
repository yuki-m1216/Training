module "Lambda" {
  source = "../../../modules/Lambda"
  providers = {
    aws.alternate = aws
  }
  lambda_filename      = data.archive_file.function.output_path
  lambda_function_name = "ConsoleLoginAlarm"
  lambda_role          = module.IAM_Role_Lambda.role_arn
  handler              = "ConsoleAlarm.lambda_handler"
  runtime              = "python3.9"
  environment_variables = {
    webhookURL = data.aws_ssm_parameter.webhookURL.value
  }

  statement_id = "AllowExecutionFromCloudWatch"
  principal    = "events.amazonaws.com"
  source_arn   = module.EventBridge_Receiver.RuleArn
}
