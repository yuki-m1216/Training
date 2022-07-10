

module "main_VPC" {
  source = "../../../modules/VPC"

# VPC
  vpc_cidr_block = "10.0.0.0/16"
  vpc_name = "Main_VPC"

# subnets
  public_subnet = {
    "public-subnet-1a" = {
      name = "public-subnet-1a"
      cidr = "10.0.0.0/24"
      az = "ap-northeast-1a"
    }
    "public-subnet-1c" = {
      name = "public-subnet-1c"
      cidr = "10.0.1.0/24"
      az = "ap-northeast-1c"
    }
  }
  private_subnet ={
    "private-subnet-1a" = {
      name = "private-subnet-1a"
      cidr = "10.0.2.0/24"
      az = "ap-northeast-1a"
    }
    "private-subnet-1c" = {
      name = "private-subnet-1c"
      cidr = "10.0.3.0/24"
      az = "ap-northeast-1c"
    }

  }

# routetable
  public_routetable_name = "main_public_routetable-01"

  private_routetable_name = "main_private_routetable-01"

# add route
  other_public_route = {
    "other-public-subnet-1a-route" = {
      destination_cidr_block    = "172.16.0.0/16"
      nat_gateway_id = null
      transit_gateway_id = null
      vpc_peering_connection_id = data.terraform_remote_state.subvpc.outputs.vpc_peering_connection_id
      vpc_endpoint_id = null
    }
  }

other_private_route = {
    "other-private-subnet-1a-route" = {
      destination_cidr_block    = "172.16.0.0/16"
      nat_gateway_id = null
      transit_gateway_id = null
      vpc_peering_connection_id = data.terraform_remote_state.subvpc.outputs.vpc_peering_connection_id
      vpc_endpoint_id = null
    }
  }

# IGW
  main_igw_name = "Main_IGW"

}


data "terraform_remote_state" "subvpc" {
  backend = "s3"

  config = {
    bucket = "s3-terraform-state-y-mitsuyama"
    key    = "SubVPC.tfstate"
    region = "ap-northeast-1"
  }
}

output "mainvpc" {
  value = module.main_VPC
}