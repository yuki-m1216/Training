#--------------------------------------------------
# Provider
#--------------------------------------------------

# default
provider "aws" {
  profile = "Y-admin"
  region  = "ap-northeast-1"
}

# # https://registry.terraform.io/providers/hashicorp/http/latest/docs
# provider "http" {
#   version = "~> 1.1"
# }
