variable "enable" {
  type        = bool
  description = "Enable monitoring and feedback reporting."
  default     = true
}

variable "finding_publishing_frequency" {
  type        = string
  description = "Specifies the frequency of notifications sent for subsequent finding occurrences."
  default     = "SIX_HOURS"
}

variable "datasources" {
  type        = map(bool)
  description = "Describes which data sources will be enabled for the detector."
}

variable "name" {
  type        = string
  description = "Name of GuardDuty"
}
