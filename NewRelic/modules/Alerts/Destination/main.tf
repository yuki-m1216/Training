resource "newrelic_notification_destination" "main" {
  account_id = var.newrelic_account_id
  name       = var.notification_destination_name
  type       = var.notification_destination_type

  property {
    key   = var.property_key
    value = var.property_value
  }
}
