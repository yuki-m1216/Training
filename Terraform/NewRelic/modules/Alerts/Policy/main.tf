resource "newrelic_alert_policy" "main" {
  account_id          = var.newrelic_account_id
  name                = var.policy_name
  incident_preference = var.incident_preference
}
