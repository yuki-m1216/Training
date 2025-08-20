### DynamoDB ###
variable "dynamodb_table" {
  type        = string
  description = "Unique within a region name of the table."
}

variable "billing_mode" {
  type        = string
  description = "Controls how you are charged for read and write throughput and how you manage capacity."
  default     = "PROVISIONED"
}

variable "read_capacity" {
  type        = number
  description = "Number of read units for this table."
  default     = 5
}

variable "write_capacity" {
  type        = number
  description = "Number of write units for this table."
  default     = 5
}

variable "hash_key" {
  type        = string
  description = "Attribute to use as the hash (partition) key."
}

variable "range_key" {
  type        = string
  description = "Attribute to use as the range (sort) key."
  default     = null
}

variable "attributes" {
  type        = list(map(string))
  description = "Set of nested attribute definitions."
}

variable "ttl_attribute_name" {
  type        = string
  description = "Name of the table attribute to store the TTL timestamp in."
  default     = ""
}

variable "ttl_enabled" {
  type        = bool
  description = "Whether TTL is enabled."
  default     = false
}

variable "global_secondary_indexes" {
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = string
    write_capacity     = number
    read_capacity      = number
    projection_type    = string
    non_key_attributes = list(string)

  }))
  description = "Describe a GSI for the table."
  default     = []
}

variable "autoscaling_enable" {
  type        = bool
  description = "autoscaling enable"
  default     = false
}


### AutoScaling ###
# read
variable "autoscaling_read" {
  type        = bool
  description = "whether to create AutoScaling read"
  default     = false
}

variable "autoscaling_read_max_capacity" {
  type        = number
  description = "read max capacity"
  default     = 20
}

variable "read_policy_target_value" {
  type        = number
  description = "read policy targetvalue"
  default     = 70
}

# read
variable "autoscaling_write" {
  type        = bool
  description = "whether to create AutoScaling write"
  default     = false
}

variable "autoscaling_write_max_capacity" {
  type        = number
  description = "write max capacity"
  default     = 20
}

variable "write_policy_target_value" {
  type        = number
  description = "write policy targetvalue"
  default     = 70
}

# AutoScaling for global secondary index 
variable "autoscaling_indexes" {
  type        = map(map(string))
  description = "autoscaling indexes configurations"
  default     = {}
}
