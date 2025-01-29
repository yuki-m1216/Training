# ECS
module "ECS_Fargate" {
  source = "../../modules/ECS"
  # ecs_cluster
  cluster_name = "test-cluster"

  # ecs_task_definition
  family = "test-task-definition"
  container_definitions = templatefile("${path.root}/container_definitions/container_definitions.tftpl",
    {
      log_group_name = local.log_group_name
      region         = local.region
      stream_prefix  = local.stream_prefix
    }
  )
  network_mode = "awsvpc"
  # ecs_service
  service_name = "test-service"
  service_subnets = [
    "subnet-073f1baa14173c1a5",
    "subnet-0c2980ee52f42fc8c",
  ]
  service_security_groups = [
    module.sg_ecs.sg_id,
  ]
  container_name = "sample-fargate-app"
  container_port = 80

  # IAM
  # execution_role
  # create customer managed policy
  # execution_customer_managed_policies = {
  # test-execution-policy-01 = file(),
  # }

  # aws managed policy
  execution_aws_managed_policies = [
    data.aws_iam_policy.ecs_task_execution_role_policy.arn,
  ]

  # task_role
  # create customer managed policy
  task_customer_managed_policies = {
    test-policy-01 = file("${path.root}/policies/test-policy-01.json"),
  }

  # aws managed policy
  # task_aws_managed_policies = []

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

  # cloudwatch_log_group
  cloudwatch_log_group_name = local.log_group_name

}


# SecurityGroup
module "sg_ecs" {
  source         = "../../modules/SecurityGroup"
  sg_name        = "test_ecs_security_group_01"
  sg_description = "test_ecs_security_group_01"
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


module "sg_lb" {
  source         = "../../modules/SecurityGroup"
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
      prefix_list_ids          = null
      description              = "HTTP from Internet"
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
