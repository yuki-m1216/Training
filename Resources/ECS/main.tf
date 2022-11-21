# ECS
module "ECS_Fargate" {
  source = "../../../modules/ECS"
  # ecs_cluster
  cluster_name = "test-cluster"

  # ecs_task_definition
  family                = "test-task-definition"
  container_definitions = templatefile("./container_definitions/container_definitions.json")

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

}

# SecurityGroup
module "sg_ecs" {
  source         = "../../../modules/SecurityGroup"
  sg_name        = "test_ECS_security_group_01"
  sg_description = "test_ECS_security_group_01"
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

