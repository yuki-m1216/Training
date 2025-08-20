# SG
variable "sg_name" {
  type        = string
  description = "Name of the security group."
}
variable "sg_description" {
  type        = string
  description = "Security group description."
  default     = "Managed by Terraform"
}
variable "sg_vpc_id" {
  type        = string
  description = "VPC ID."
}

# SG Rule
variable "sg_rule" {
  type = map(object({
    type                     = string
    to_port                  = number
    from_port                = number
    protocol                 = string
    source_security_group_id = string
    cidr_blocks              = list(string)
    prefix_list_ids          = list(string)
    description              = string
  }))
  description = "Provides a security group rule resource."
  default     = null
}
