variable "NEW_RELIC_ACCOUNT_ID" {
  type        = string
  description = "NEW RELIC ACCOUNT ID"
}

variable "subscription_filters" {
  type = map(object({
    log_group_name = string
    filter_pattern = string
  }))
  description = "Subscription filter for New Relic"
  default     = null
}
