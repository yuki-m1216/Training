# SG
variable "sg_name" {}
variable "sg_description" {}
variable "sg_vpc_id" {}

# SG Rule
variable "sg_rule" {
  type    = map(any)
  default = {}
}