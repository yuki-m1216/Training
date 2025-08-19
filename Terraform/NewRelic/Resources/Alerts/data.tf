data "aws_ssm_parameter" "newrelic_alert" {
  name = "/webhookURL/NewRelicAlert"
}