variable "newrelic_account_id" {
  type        = string
  description = "The New Relic account ID of the account you wish to create the condition. Defaults to the account ID set in your environment variable"
  default     = null
}

variable "notification_channel_name" {
  type        = string
  description = "The name of the channel."
}

variable "notification_channel_type" {
  type        = string
  description = <<-EOT
    The type of channel. 
    One of: EMAIL, SERVICENOW_INCIDENTS, SERVICE_NOW_APP, WEBHOOK, JIRA_CLASSIC, MOBILE_PUSH, EVENT_BRIDGE, SLACK and SLACK_COLLABORATION, 
    PAGERDUTY_ACCOUNT_INTEGRATION or PAGERDUTY_SERVICE_INTEGRATION.
  EOT
}

variable "notification_destination_id" {
  type        = string
  description = "The ID of the destination."
}

variable "webhook_properties" {
  type = list(object({
    header_key    = string
    header_value  = string
    payload_key   = string
    payload_value = string
  }))
  description = "The properties for the webhook."
}

variable "workflow_name" {
  type        = string
  description = "The name of the workflow."
}

variable "workflow_enabled" {
  type        = bool
  description = "Whether the workflow is enabled. Defaults to true."
  default     = true
}

variable "muting_rules_handling" {
  type        = string
  description = <<-EOT
    How to handle muted issues. 
    Possible values are DONT_NOTIFY_FULLY_MUTED_ISSUES, DONT_NOTIFY_FULLY_OR_PARTIALLY_MUTED_ISSUES, NOTIFY_ALL_ISSUES. 
  EOT
  default     = "DONT_NOTIFY_FULLY_MUTED_ISSUES"
}

variable "issues_filter_name" {
  type        = string
  description = "The name of the filter."
  default     = "workflow_filter"
}

variable "predicate_policy_attribute" {
  type        = string
  description = "The attribute of the policy."
  default     = "labels.policyIds"
}

variable "predicate_policy_operator" {
  type        = string
  description = <<-EOT
    The operator of the policy. 
    Possible values are EXACTLY_MATCHES, DOES_NOT_EXACTLY_MATCH, CONTAINS, DOES_NOT_CONTAIN. 
    Default is EXACTLY_MATCHES.
  EOT
  default     = "EXACTLY_MATCHES"
}

variable "workflow_isue_filter_predicate_values" {
  type        = list(string)
  description = " a list of IDs of alert policies that triggered the incidents included in the issue"
}

variable "predicate_priority_attribute" {
  type        = string
  description = "The attribute of the priority."
  default     = "priority"
}

variable "predicate_priority_operator" {
  type        = string
  description = "The operator of the priority."
  default     = "EQUAL"
}

variable "predicate_priority_values" {
  type        = list(string)
  description = "The values of the priority."
  default     = ["CRITICAL", "HIGH"]
}

variable "notification_triggers" {
  type        = list(string)
  description = <<-EOT
    The triggers for the notification. 
    Possible values are ACTIVATED, ACKNOWLEDGED, PRIORITY_CHANGED, CLOSED, OTHER_UPDATES
  EOT
  default     = ["ACKNOWLEDGED", "ACTIVATED", "CLOSED", "OTHER_UPDATES", "PRIORITY_CHANGED"]
}
