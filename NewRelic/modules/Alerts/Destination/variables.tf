variable "newrelic_account_id" {
  type        = string
  description = "The New Relic account ID of the account you wish to create the condition. Defaults to the account ID set in your environment variable"
  default     = null
}

variable "notification_destination_name" {
  type        = string
  description = "The name of the destination."
}

variable "notification_destination_type" {
  type        = string
  description = <<-EOT
    The type of destination. 
    One of: EMAIL, SERVICE_NOW, SERVICE_NOW_APP, WEBHOOK, JIRA, MOBILE_PUSH, EVENT_BRIDGE, PAGERDUTY_ACCOUNT_INTEGRATION or PAGERDUTY_SERVICE_INTEGRATION. 
    The types SLACK and SLACK_COLLABORATION can only be imported, updated and destroyed (cannot be created via terraform).
  EOT
}

variable "property_key" {
  type        = string
  description = <<-EOT
    The notification property key.
    https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/notification_channel#nested-property-blocks
  EOT
}

variable "property_value" {
  type        = string
  description = <<-EOT
    The notification property value.
    https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/notification_channel#nested-property-blocks
  EOT
}
