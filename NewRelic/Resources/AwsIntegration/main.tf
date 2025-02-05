module "AwsIntergration" {
  source = "../../modules/AwsIntegration"

  NEW_RELIC_ACCOUNT_ID   = var.NEW_RELIC_ACCOUNT_ID
  NEW_RELIC_ACCOUNT_NAME = "Integration"
}
