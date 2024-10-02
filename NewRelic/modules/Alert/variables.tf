variable "newrelic_account_id" {
  type        = string
  description = "The New Relic account ID of the account you wish to create the condition. Defaults to the account ID set in your environment variable"
  default     = null
}

variable "policy_name" {
  type        = string
  description = "The rollup strategy for the policy, which can have one of the following values (the default value is PER_POLICY)"
  default     = "PER_POLICY"
}

variable "incident_preference" {
  type        = string
  description = "The incident preference for the policy. Valid values are PER_POLICY and PER_CONDITION. Defaults to PER_POLICY."
  default     = "PER_POLICY"
}

variable "condition_type" {
  type        = string
  description = "The type of the condition. Valid values are static or baseline. Defaults to static."
  default     = "static"
}

variable "condition_name" {
  type        = string
  description = "The title of the condition."
}

variable "condition_enabled" {
  type        = bool
  description = "Whether the condition is enabled. Defaults to true."
  default     = true
}

variable "violation_time_limit_seconds" {
  type        = number
  description = "Sets a time limit, in seconds, that will automatically force-close a long-lasting incident after the time limit you select. The value must be between 300 seconds (5 minutes) to 2592000 seconds (30 days) (inclusive)."
  default     = 2592000
}

variable "condition_query" {
  type        = string
  description = "The NRQL query to execute for the condition."
}

variable "critical" {
  type = list(object({
    operator              = string
    threshold             = number
    threshold_duration    = number
    threshold_occurrences = string
  }))
  description = "The critical threshold for the condition."
}

variable "warning" {
  type = list(object({
    operator              = string
    threshold             = number
    threshold_duration    = number
    threshold_occurrences = string
  }))
  description = "The warning threshold for the condition."
}

variable "fill_option" {
  type        = string
  description = " Which strategy to use when filling gaps in the signal. Possible values are none, last_value or static. If static, the fill_value field will be used for filling gaps in the signal."
  default     = "none"
}

variable "fill_value" {
  type        = number
  description = "Required when fill_option is static. This value will be used for filling gaps in the signal."
  default     = null
}

variable "aggregation_window" {
  type        = number
  description = "The duration of the time window used to evaluate the NRQL query, in seconds. The value must be at least 30 seconds, and no more than 21600 seconds (6 hours). Default is 60 seconds."
  default     = 60
}

variable "aggregation_method" {
  type        = string
  description = "Determines when we consider an aggregation window to be complete so that we can evaluate the signal for incidents. Possible values are cadence, event_flow or event_timer. Default is event_flow."
  default     = "event_flow"
}

variable "aggregation_delay" {
  type        = number
  description = <<-EOT
    How long we wait for data that belongs in each aggregation window. 
    Depending on your data, a longer delay may increase accuracy but delay notifications. 
    Use aggregation_delay with the event_flow and cadence methods. 
    The maximum delay is 1200 seconds (20 minutes) when using event_flow and 3600 seconds (60 minutes) when using cadence. 
    In both cases, the minimum delay is 0 seconds and the default is 120 seconds.
  EOT
  default     = 60
}

variable "baseline_direction" {
  type        = string
  description = "The baseline direction of a baseline NRQL alert condition. Valid values are: lower_only, upper_and_lower, upper_only (case insensitive)."
  default     = "upper_and_lower"
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
  description = "The notification property key."
}

variable "property_value" {
  type        = string
  description = "The notification property value."
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

variable "notification_channel_product" {
  type        = string
  description = "The type of product. One of: DISCUSSIONS, ERROR_TRACKING or IINT (workflows)."
  default     = "IIINT"
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
    Default is MUTING_RULES_IGNORE.
  EOT
  default     = "MUTING_RULES_IGNORE"
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
