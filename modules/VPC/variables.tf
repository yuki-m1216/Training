# vpc
variable "vpc_cidr_block" {}
variable "vpc_name" {}

# public subnets
variable "public_subnet" {
  type    = map(any)
  default = {}
}

# private subnets
variable "private_subnet" {
  type    = map(any)
  default = {}
}

# routetable
variable "public_routetable_name" {}

variable "private_routetable_name" {}

# IGW
variable "main_igw_name" {}

# other route
# public
variable "other_public_route" {
  type    = map(any)
  default = {}
}

# private
variable "other_private_route" {
  type    = map(any)
  default = {}
}

# nat
variable "nat_gateway_create" {
  type    = string
  default = "false"
}
