

module "Sub_VPC" {
  source = "../../../modules/VPC"

  # VPC
  vpc_cidr_block = "172.16.0.0/16"
  vpc_name       = "Sub_VPC"

  # subnets
  public_subnet = {
    "sub-public-subnet-1a" = {
      name = "sub-public-subnet-1a"
      cidr = "172.16.0.0/24"
      az   = "ap-northeast-1a"
    }
    "sub-public-subnet-1c" = {
      name = "sub-public-subnet-1c"
      cidr = "172.16.1.0/24"
      az   = "ap-northeast-1c"
    }
  }
  private_subnet = {
    "sub-private-subnet-1a" = {
      name = "sub-private-subnet-1a"
      cidr = "172.16.2.0/24"
      az   = "ap-northeast-1a"
    }
    "sub-private-subnet-1c" = {
      name = "sub-private-subnet-1c"
      cidr = "172.16.3.0/24"
      az   = "ap-northeast-1c"
    }

  }

  # routetable
  public_routetable_name = "sub_public_routetable-01"

  private_routetable_name = "sub_private_routetable-01"

  # add route
  other_public_route = {
    "other-public-subnet-1a-route" = {
      target_subnet             = "sub-public-subnet-1a"
      destination_cidr_block    = "10.0.0.0/16"
      nat_gateway_id            = null
      transit_gateway_id        = null
      vpc_peering_connection_id = aws_vpc_peering_connection.sub-to-main-peering.id
      vpc_endpoint_id           = null
    }
  }

  other_private_route = {
    "other-private-subnet-1a-route" = {
      target_subnet             = "sub-private-subnet-1a"
      destination_cidr_block    = "10.0.0.0/16"
      nat_gateway_id            = null
      transit_gateway_id        = null
      vpc_peering_connection_id = aws_vpc_peering_connection.sub-to-main-peering.id
      vpc_endpoint_id           = null
    }
  }


  # IGW
  main_igw_name = "Sub_IGW"

}

# vpc peering
resource "aws_vpc_peering_connection" "sub-to-main-peering" {
  peer_vpc_id = data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id
  vpc_id      = module.Sub_VPC.mainvpc_id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
  tags = {
    Name = "Sub-to-Main-Peering"
  }
}

data "terraform_remote_state" "mainvpc" {
  backend = "s3"

  config = {
    bucket = "s3-terraform-state-y-mitsuyama"
    key    = "MainVPC.tfstate"
    region = "ap-northeast-1"
  }
}


output "mainvpc" {
  value = module.Sub_VPC
}

output "vpc_peering_connection_id" {
  value = aws_vpc_peering_connection.sub-to-main-peering.id
}
