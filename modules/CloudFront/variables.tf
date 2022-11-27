# cloud front
variable "origin" {
  type = list(object({
    domain_name              = string
    origin_access_control_id = string
    origin_id                = string
    origin_path              = string

    custom_header = list(object({
      name  = string
      value = string
    }))

    origin_shield_enabled = string
    origin_shield_region  = string

    connection_attempts = number
    connection_timeout  = number

  }))
  description = "One or more origins for this distribution (multiples allowed)."
}
