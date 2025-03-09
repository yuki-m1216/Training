# security_policy
variable "security_poloicy_name" {
  description = "The name of the security policy"
  type        = string
}

variable "security_policy_type" {
  description = "The type of the security policy"
  type        = string

  validation {
    condition     = var.security_policy_type == "encryption " || var.security_policy_type == "network"
    error_message = "The security policy type must be either 'encryption' or 'network'"
  }
}

variable "security_policy_description" {
  description = "The description of the security policy"
  type        = string
}

variable "security_policy" {
  description = "The security policy"
  type        = string
}

# access_policy
variable "access_plicy_name" {
  description = "The name of the access policy"
  type        = string
}

variable "access_policy_description" {
  description = "The description of the access policy"
  type        = string
}

variable "access_policy" {
  description = "The access policy"
  type        = string
}

# collection
variable "collection_name" {
  description = "The name of the collection"
  type        = string
}

variable "collection_description" {
  description = "The description of the collection"
  type        = string
}

variable "collection_type" {
  description = "The type of the collection"
  type        = string
  default = "TIMESERIES"

  validation {
    condition     = var.collection_type == "SEARCH" || var.collection_type == "TIMESERIES" || var.collection_type == "VECTORSEARCH"
    error_message = "The collection type must be either 'SEARCH' or 'TIMESERIES' or 'VECTORSEARCH'"
  }
}

variable "standby_replicas" {
  description = "The number of standby replicas"
  type        = string
  default     = "ENABLED"

  validation {
    condition     = var.standby_replicas == "ENABLED" || var.standby_replicas == "DISABLED"
    error_message = "The standby replicas must be either 'ENABLED' or 'DISABLED'"
  }
}

variable "collection_tags" {
  description = "The tags of the collection"
  type        = map(any)
}