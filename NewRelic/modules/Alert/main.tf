resource "newrelic_alert_policy" "main" {
  account_id = var.newrelic_account_id
  name = var.policy_name
  incident_preference = var.incident_preference
}

resource "newrelic_nrql_alert_condition" "main" {
  account_id = var.newrelic_account_id
  policy_id = newrelic_alert_policy.main.id
  type = var.condition_type
  name = var.condition_name
  enabled = var.condition_enabled
  violation_time_limit_seconds = var.violation_time_limit_seconds

  nrql {
    query = var.condition_query
  }

  dynamic "critical" {
    for_each = var.critical
    content {
      operator = critical.value.operator
      threshold = critical.value.threshold
      threshold_duration = critical.value.threshold_duration
      threshold_occurrences = critical.value.threshold_occurrences
    }
    
  }

  dynamic "warning" {
    for_each = var.warning
    content {
      operator = warning.value.operator
      threshold = warning.value.threshold
      threshold_duration = warning.value.threshold_duration
      threshold_occurrences = warning.value.threshold_occurrences
    }
  }

  fill_option = var.fill_option
  fill_value = var.fill_option == "static" ? var.fill_value : null
  aggregation_window = var.aggregation_window
  aggregation_method = var.aggregation_method
  aggregation_delay = var.aggregation_method != "event_timer" ? var.aggregation_delay : null
  baseline_direction = var.baseline_direction
}
