# vpc
variable "vpc_cidr_block" {}
variable "vpc_name" {}
variable "vpc_tags" {
  type    = map(any)
  default = {}
}


# public subnets
variable "public_subnet" {
  type = map(object({
    name = string
    cidr = string
    az   = string
    tags = map(string)
  }))
  default = {}
}

# private subnets
variable "private_subnet" {
  type = map(object({
    name = string
    cidr = string
    az   = string
    tags = map(string)
  }))
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
  type    = bool
  default = false
}
