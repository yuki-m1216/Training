variable "newrelic_account_id" {
  type        = string
  description = "The New Relic account ID of the account you wish to create the condition. Defaults to the account ID set in your environment variable"
  default     = null
}

variable "policy_id" {
  type        = string
  description = "The ID of the policy to associate the condition with."
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
  default     = []
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

variable "aggregation_timer" {
  type        = number
  description = <<-EOT
    How long we wait after each data point arrives to make sure we've processed the whole batch.
    Use aggregation_timer with the event_timer method. 
    The timer value can range from 0 seconds to 1200 seconds (20 minutes); the default is 60 seconds. 
  EOT
  default     = 60

}


variable "baseline_direction" {
  type        = string
  description = "The baseline direction of a baseline NRQL alert condition. Valid values are: lower_only, upper_and_lower, upper_only (case insensitive)."
  default     = "upper_and_lower"
}
