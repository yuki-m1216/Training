# EC2_AutoScaling
module "EC2_AutoScaling" {
  source = "../../../modules/EC2_AutoScaling"
  # launch_template
  name_prefix            = "test_template"
  image_id               = "ami-0b7546e839d7ace12"
  instance_type          = "t2.micro"
  user_data              = filebase64("userdata/example.sh")
  vpc_security_group_ids = [module.sg_launch_template.sg_id]

  # autoscaling_group
  autoscaling_group_name = "test_autoscaling_group"

  vpc_zone_identifier = [
    "subnet-073f1baa14173c1a5"
  ]
  desired_capacity  = 1
  max_size          = 1
  min_size          = 1
  health_check_type = "EC2"

  # lb
  alb_name           = "test-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    module.sg_lb.sg_id
  ]
  subnets = [
    "subnet-0ef3a322300e969c2",
    "subnet-03ad5ab676aea8179"
  ]

  # target_group
  target_group_name     = "test-target-group"
  target_group_port     = 80
  target_group_protocol = "HTTP"
  target_group_vpc_id   = "vpc-05b5aeed5c9d8e83e"

  # lb_listener
  listener = {
    "listener_01" = {
      port     = "80"
      protocol = "HTTP"
    }
  }


}

# SecurityGroup
module "sg_launch_template" {
  source         = "../../../modules/SecurityGroup"
  sg_name        = "test_AS_security_group_01"
  sg_description = "test_AS_security_group_01"
  sg_vpc_id      = "vpc-05b5aeed5c9d8e83e"

  sg_rule = {
    "ingress_01" = {
      type                     = "ingress"
      to_port                  = 80
      from_port                = 80
      protocol                 = "tcp"
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      description              = "HTTP from Internet"
    }
    "ingress_02" = {
      type                     = "ingress"
      to_port                  = 443
      from_port                = 443
      protocol                 = "tcp"
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      description              = "HTTPS from Internet"
    }
    "egress_01" = {
      type                     = "egress"
      to_port                  = 0
      from_port                = 0
      protocol                 = "-1"
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      description              = "Allow any outbound traffic"
    }
  }
}

module "sg_lb" {
  source         = "../../../modules/SecurityGroup"
  sg_name        = "test_lb_security_group_01"
  sg_description = "test_lb_security_group_01"
  sg_vpc_id      = "vpc-05b5aeed5c9d8e83e"

  sg_rule = {
    "ingress_01" = {
      type                     = "ingress"
      to_port                  = 80
      from_port                = 80
      protocol                 = "tcp"
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      description              = "HTTP from Internet"
    }
    "ingress_02" = {
      type                     = "ingress"
      to_port                  = 443
      from_port                = 443
      protocol                 = "tcp"
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      description              = "HTTPS from Internet"
    }
    "egress_01" = {
      type                     = "egress"
      to_port                  = 0
      from_port                = 0
      protocol                 = "-1"
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      description              = "Allow any outbound traffic"
    }
  }
}




output "EC2_AutoScaling" {
  value = module.EC2_AutoScaling
}
