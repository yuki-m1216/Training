module "main_policy" {
  source = "../../modules/Alerts/Policy"

  newrelic_account_id = var.NEW_RELIC_ACCOUNT_ID
  policy_name         = "main-policy"
  incident_preference = "PER_POLICY"
}

module "log_error_condition" {
  source = "../../modules/Alerts/AlertCondition"

  newrelic_account_id          = var.NEW_RELIC_ACCOUNT_ID
  policy_id                    = module.main_policy.alert_policy_id
  condition_type               = "static"
  condition_name               = "main-condition"
  condition_enabled            = true
  violation_time_limit_seconds = 2592000
  condition_query              = "SELECT count(*) FROM Log WHERE message LIKE '%error%'"
  critical = [
    {
      operator              = "above"
      threshold             = 1
      threshold_duration    = 5
      threshold_occurrences = "all"
    }
  ]

  fill_option        = "none"
  aggregation_window = 1
  aggregation_method = "event_timer"
  aggregation_timer  = 1
}

module "log_error_destination" {
  source = "../../modules/Alerts/Destination"

  newrelic_account_id           = var.NEW_RELIC_ACCOUNT_ID
  notification_destination_name = "log-error-destination"
  notification_destination_type = "WEBHOOK"
  property_key                  = "url"
  property_value                = data.aws_ssm_parameter.newrelic_alert.value
}

module "log_error_workflow" {
  source = "../../modules/Alerts/Workflow"

  newrelic_account_id         = var.NEW_RELIC_ACCOUNT_ID
  notification_channel_name   = module.log_error_destination.notification_destination_name
  notification_channel_type   = module.log_error_destination.notification_destination_type
  notification_destination_id = module.log_error_destination.notification_destination_id
  webhook_properties = [
    {
      header_key   = "headers"
      header_value = "{}"
      payload_key  = "payload"
      payload_value = trimspace(<<-EOT
    {
        "blocks": [
          {
            "type": "section",
           "text": {
              "text": "test alert",
              "type": "mrkdwn"
            }
          }
        ]
    }
    EOT
      )
    }
  ]
  workflow_name               = "log-error-workflow"
  workflow_isue_filter_predicate_values = [module.main_policy.alert_policy_id]
}
