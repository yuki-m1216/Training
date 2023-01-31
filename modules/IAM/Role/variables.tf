# IAM Role
variable "role_name" {
  type        = string
  description = "Friendly name of the role."
}

variable "custom_assume_role_policy" {
  type        = any
  description = "Trusted entity is not AWS service"
  default     = null
}

# Assume Role Policy 
variable "trusted_entity_aws_service" {
  type        = bool
  description = "Whether the trusted entity is AWS service"
  default     = true
}

variable "identifiers" {
  type        = string
  description = "identifiers"
  default     = null
}

# IAM Policy
variable "create_policies" {
  type        = map(string)
  description = "map of policies"
  default     = {}
}


# IAM Role Policy Attachment
variable "policies" {
  type        = list(string)
  description = "list of already created policies arn"
  default     = []
}
