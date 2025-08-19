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
