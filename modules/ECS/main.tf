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
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

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
  name                               = var.service_name
  cluster                            = aws_ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  # https://qiita.com/HirokiSakonju/items/18e532fcf1461876c4f3
  # https://qiita.com/horietakehiro/items/5f5d9166b26bfb4287dd
  iam_role = (
    var.network_mode != "awsvpc" ? var.service_linked_role_created ?
    data.aws_iam_role.ecs_service_linked_role.arn : aws_iam_service_linked_role.ecs_service_linked_role.arn : null
  )

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

# IAM
# execution_role
resource "aws_iam_role" "execution_role" {
  name        = "${var.family}-TaskExecutionRole"
  description = "ECS TaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${var.family}-TaskExecutionRole"
  }
}

resource "aws_iam_policy" "execution_role_policy" {
  name   = "${var.family}-TaskExecutionPolicy"
  policy = var.execution_role_policy
}

resource "aws_iam_role_policy_attachment" "execution_role_policy_attach" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.execution_role_policy.arn
}

# task_role
resource "aws_iam_role" "task_role" {
  name        = "${var.family}-TaskRole"
  description = "ECS TaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "task_role_policy" {
  name   = "${var.family}-TaskPolicy"
  policy = var.task_role_policy
}

resource "aws_iam_role_policy_attachment" "task_role_policy_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_policy.arn
}

# service_linked_role
resource "aws_iam_service_linked_role" "ecs_service_linked_role" {
  count            = var.service_linked_role_created ? 0 : 1
  aws_service_name = "ecs.amazonaws.com"
}

data "aws_iam_role" "ecs_service_linked_role" {
  count = var.service_linked_role_created ? 1 : 0
  name  = "AWSServiceRoleForECS"
}

# lb
