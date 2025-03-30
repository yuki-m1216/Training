resource "aws_security_group" "ecr" {
    name        = "ecr-sg"
    description = "ECR security group"
    vpc_id      = data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id
    tags = {
        Name = "ecr-sg"
    }
}

resource "aws_vpc_security_group_ingress_rule" "ecr" {
    security_group_id = aws_security_group.ecr.id
    from_port = 443
    to_port = 443
    ip_protocol = "tcp"
    cidr_ipv4 = data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_cidr_block
}

resource "aws_vpc_endpoint" "ecr_dkr" {
    vpc_id = data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id
    service_name = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
    vpc_endpoint_type = "Interface"
    security_group_ids = [aws_security_group.ecr.id]
    subnet_ids = [
        data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id["private-subnet-1a"],
        data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id["private-subnet-1c"]
    ]
    private_dns_enabled = true
    tags = {
        Name = "ecr-dkr-vpc-endpoint"
    }
}

resource "aws_vpc_endpoint" "ecr_api" {
    vpc_id = data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id
    service_name = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
    vpc_endpoint_type = "Interface"
    security_group_ids = [aws_security_group.ecr.id]
    subnet_ids = [
        data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id["private-subnet-1a"],
        data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id["private-subnet-1c"]
    ]
    private_dns_enabled = true
    tags = {
        Name = "ecr-api-vpc-endpoint"
    } 
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id = data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id
    service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
    vpc_endpoint_type = "Gateway"
    route_table_ids = [
        data.terraform_remote_state.mainvpc.outputs.mainvpc.private_routetable["private-subnet-1a"],
        data.terraform_remote_state.mainvpc.outputs.mainvpc.private_routetable["private-subnet-1c"]
    ]
    tags = {
        Name = "s3-vpc-endpoint"
    }
}

resource "aws_vpc_endpoint" "cwl" {
    vpc_id = data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id
    service_name = "com.amazonaws.${data.aws_region.current.name}.logs"
    vpc_endpoint_type = "Interface"
    security_group_ids = [aws_security_group.ecr.id]
    subnet_ids = [
        data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id["private-subnet-1a"],
        data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id["private-subnet-1c"]
    ]
    private_dns_enabled = true
    tags = {
        Name = "cwl-vpc-endpoint"
    }
}
