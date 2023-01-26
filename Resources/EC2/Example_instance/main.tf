# EC2
module "ec2" {
  source = "../../../modules/EC2"

  ec2 = {
    "example-ec2" = {
      ami                     = "ami-0b7546e839d7ace12"
      instance_type           = "t2.micro"
      disable_api_stop        = false
      disable_api_termination = true
      # ebs_block_device = null
      ebs_optimized          = null
      iam_instance_profile   = null
      key_name               = "test_key_pair"
      monitoring             = false
      private_ip             = null
      vpc_security_group_ids = [module.sg.sg_id]
      subnet_id              = "subnet-0ef3a322300e969c2"
      ec2_name               = "Test_EC2"
      user_data              = null
      delete_on_termination  = true
      encrypted              = true
      iops                   = null
      kms_key_id             = data.aws_kms_key.current.arn
      throughput             = null
      volume_size            = 8
      volume_type            = "gp2"
    }
  }
}

module "sg" {
  source         = "../../../modules/SecurityGroup"
  sg_name        = "security_group_01"
  sg_description = "security_group_01"
  sg_vpc_id      = "vpc-05b5aeed5c9d8e83e"

  sg_rule = {
    "ingress_01" = {
      type                     = "ingress"
      to_port                  = 80
      from_port                = 80
      protocol                 = "tcp"
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      prefix_list_ids          = null
      description              = "HTTP from Internet"
    }
    "ingress_02" = {
      type                     = "ingress"
      to_port                  = 443
      from_port                = 443
      protocol                 = "tcp"
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      prefix_list_ids          = null
      description              = "HTTPS from Internet"
    }
    "egress_01" = {
      type                     = "egress"
      to_port                  = 0
      from_port                = 0
      protocol                 = "-1"
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      prefix_list_ids          = null
      description              = "Allow any outbound traffic"
    }
  }

}


# kms
# get the default EBS encryption KMS key in the current region.
data "aws_ebs_default_kms_key" "current" {}

# https://github.com/hashicorp/terraform-provider-aws/issues/15137#issuecomment-691730866
data "aws_kms_key" "current" {
  key_id = data.aws_ebs_default_kms_key.current.key_arn
}


output "ec2" {
  value = module.ec2
}
