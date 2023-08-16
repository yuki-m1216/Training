# host zone
variable "create_hostzone" {
  type        = bool
  description = "whether create host zone"
  default     = false
}

variable "hostzone_name" {
  type        = string
  description = "This is the name of the hosted zone."
  default     = null
}

# record
variable "create_record" {
  type        = bool
  description = "whether create host zone"
  default     = false
}

variable "zone_id" {
  type        = string
  description = "The ID of the hosted zone to contain this record."
  default     = null
}

variable "record_name" {
  type        = string
  description = "The name of the record."
  default     = null
}

variable "type" {
  type        = string
  description = "The record type."
  default     = "A"
}

variable "alias" {
  type = list(object({
    name                   = string
    zone_id                = string
    evaluate_target_health = bool
  }))
  default = null
}
