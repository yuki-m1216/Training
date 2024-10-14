module "forward_aws_logs" {
  source = "../../modules/ForwardAwsLogs"

  NEW_RELIC_ACCOUNT_ID = var.NEW_RELIC_ACCOUNT_ID

  subscription_filters = {
    "lambda-console-login" =  {
      log_group_name = "/aws/lambda/ConsoleLoginAlarm"
      filter_pattern = ""
  }
  }
}
