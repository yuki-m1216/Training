# ecs_cluster
resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.containerInsights
  }
  tags = {
    Name = var.cluster_name
  }
}

# ecs_task_definition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = var.family
  requires_compatibilities = [var.requires_compatibilities]
  container_definitions    = var.container_definitions
  network_mode             = var.requires_compatibilities == "FARGATE" ? "awsvpc" : var.network_mode
  cpu                      = var.cpu
  memory                   = var.memory
  # todo
  execution_role_arn = aws_iam_role.foo.arn
  # todo
  task_role_arn = aws_iam_role.foo.arn

  # https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform
  dynamic "runtime_platform" {
    for_each = var.requires_compatibilities == "FARGATE" ? [1] : []
    content {
      operating_system_family = var.operating_system_family
      cpu_architecture        = var.cpu_architecture
    }
  }

  tags = {
    Name = var.family
  }
}

# ecs_service
resource "aws_ecs_service" "service" {
  name    = var.service_name
  cluster = aws_ecs_cluster.cluster.id
  # todo
  task_definition                    = aws_ecs_task_definition.mongo.arn
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  # todo
  iam_role   = var.network_mode != "awsvpc" ? aws_iam_role.foo.arn : null
  depends_on = [aws_iam_role_policy.foo]

  enable_execute_command = var.enable_execute_command
  launch_type            = var.launch_type
  platform_version       = var.launch_type == "FARGATE" ? var.platform_version : null
  network_configuration {
    assign_public_ip = var.launch_type == "FARGATE" ? var.assign_public_ip : null
    subnets          = var.service_subnets
    security_groups  = var.service_security_groups
  }

  propagate_tags                    = var.propagate_tags
  health_check_grace_period_seconds = var.health_check_grace_period_seconds


  deployment_controller {
    type = var.deployment_controller_type
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_controller_type == "ECS" ? [1] : []
    content = {
      enable   = true
      rollback = true
    }
  }

  tags = {
    Name = var.service_name
  }
  # todo 
  # https://www.sunnycloud.jp/column/20210625-01/
  # https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/task-placement-strategies.html
  # ordered_placement_strategy {
  #   type  = "binpack"
  #   field = "cpu"
  # }

  # https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/task-placement-constraints.html
  # placement_constraints {
  #   type       = "memberOf"
  #   expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  # }

  # todo
  load_balancer {
    target_group_arn = aws_lb_target_group.foo.arn
    container_name   = "mongo"
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

}
