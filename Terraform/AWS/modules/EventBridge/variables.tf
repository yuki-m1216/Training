# Rule
variable "rule_name" {}
variable "rule_description" {
  default = null
}
variable "event_pattern" {
  type    = string
  default = null
}
variable "schedule_expression" {
  default = null
}
variable "is_enabled" {
  default = true
}

variable "state" {
  default     = "ENABLED"
  description = "value can be ENABLED or DISABLED or ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS"
}
variable "rule_tags" {
  type    = map(any)
  default = null
}

# Target
variable "target_id" {
  default = null
}
variable "target_arn" {}
variable "target_role_arn" {
  default = null
}
variable "input" {
  default = null
}
variable "input_path" {
  default = null
}
variable "input_transformer_input_paths" {
  default = null
}
variable "input_transformer_input_template" {
  default = null
}

# EventBus
variable "create_event_bus" {
  default = false
}
variable "event_bus_name" {
  default = null
}