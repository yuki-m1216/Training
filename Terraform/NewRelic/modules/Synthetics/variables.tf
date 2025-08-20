variable "script_monitor_status" {
  type        = string
  description = "The run state of the monitor. (ENABLED or DISABLED)."
  default     = "ENABLED"
}

variable "script_monitor_name" {
  type        = string
  description = "The name for the monitor."
}

variable "script_monitor_type" {
  type        = string
  description = "The plaintext representing the monitor script. Valid values are SCRIPT_BROWSER or SCRIPT_API"
  default     = "SCRIPT_API"
}

variable "script_monitor_locations_public" {
  type        = list(string)
  description = <<-EOF
    The location the monitor will run from.
    Check out https://docs.newrelic.com/docs/synthetics/synthetic-monitoring/administration/synthetic-public-minion-ips/
    EOF
  default     = ["AWS_AP_NORTHEAST_1"]
}

variable "script_monitor_period" {
  type        = string
  description = <<-EOF
    The interval at which this monitor should run.
    Valid values are EVERY_MINUTE, EVERY_5_MINUTES, EVERY_10_MINUTES, EVERY_15_MINUTES, EVERY_30_MINUTES, EVERY_HOUR, EVERY_6_HOURS, EVERY_12_HOURS, or EVERY_DAY
    EOF
  default     = "EVERY_6_HOURS"
}

variable "script_monitor_script" {
  type        = string
  description = " The script that the monitor runs."
}

variable "script_monitor_runtime_type" {
  type        = string
  description = <<-EOF
    The runtime that the monitor will use to run jobs.
    For the SCRIPT_API monitor type, a valid value is NODE_API. 
    For the SCRIPT_BROWSER monitor type, a valid value is CHROME_BROWSER.
    EOF
  default     = "NODE_API"
}

variable "script_monitor_runtime_type_version" {
  type        = string
  description = <<-EOF
    The specific version of the runtime type selected.
    For the SCRIPT_API monitor type, a valid value is 16.10, which corresponds to the version of Node.js. 
    For the SCRIPT_BROWSER monitor type, a valid value is 100, which corresponds to the version of the Chrome browser. 
    EOF
  default     = "16.10"
}

variable "script_monitor_tag" {
  type = list(object({
    key    = string
    values = list(string)
  }))
  description = "The tags that will be associated with the monitor."
  default = [{
    key    = "Environment"
    values = ["dev"]
  }]
}
