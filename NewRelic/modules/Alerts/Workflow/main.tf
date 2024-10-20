resource "newrelic_notification_channel" "main" {
  account_id     = var.newrelic_account_id
  name           = var.notification_channel_name
  type           = var.notification_channel_type
  destination_id = var.notification_destination_id
  product        = "IINT"

  dynamic "property" {
    for_each = var.webhook_properties
    content {
      key   = property.value.header_key
      value = property.value.header_value
    }
  }

  dynamic "property" {
    for_each = var.webhook_properties
    content {
      key   = property.value.payload_key
      value = property.value.payload_value
    }
  }
}

resource "newrelic_workflow" "workflow" {
  account_id            = var.newrelic_account_id
  name                  = var.workflow_name
  enabled               = var.workflow_enabled
  muting_rules_handling = var.muting_rules_handling

  issues_filter {
    name = var.issues_filter_name
    type = "FILTER"

    predicate {
      attribute = var.predicate_policy_attribute
      operator  = var.predicate_policy_operator
      values    = var.workflow_isue_filter_predicate_values
    }

    predicate {
      attribute = var.predicate_priority_attribute
      operator  = var.predicate_priority_operator
      values    = var.predicate_priority_values
    }
  }

  destination {
    channel_id              = newrelic_notification_channel.main.id
    notification_triggers   = var.notification_triggers
    update_original_message = true
  }
}
