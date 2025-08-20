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
    data.aws_iam_role.ecs_service_linked_role[0].arn : aws_iam_service_linked_role.ecs_service_linked_role[0].arn : null
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
    content {
      enable   = var.circuit_breaker_deployment_enabled
      rollback = var.circuit_breaker_rollback_enabled
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

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = var.container_name
    container_port   = var.container_port
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

# create customer managed policy
resource "aws_iam_policy" "execution_role_policy" {
  for_each = var.execution_customer_managed_policies
  name     = "${var.family}-TaskExecutionPolicy-${each.key}"
  policy   = each.value
}

resource "aws_iam_role_policy_attachment" "execution_role_policy_attach_customer_managed" {
  for_each   = var.execution_customer_managed_policies
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.execution_role_policy[each.key].arn
}

# aws managed policy
resource "aws_iam_role_policy_attachment" "execution_role_policy_attach_aws_managed" {
  for_each   = toset(var.execution_aws_managed_policies)
  role       = aws_iam_role.execution_role.name
  policy_arn = each.value
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

# create customer managed policy
resource "aws_iam_policy" "task_role_policy" {
  for_each = var.task_customer_managed_policies
  name     = "${var.family}-TaskPolicy-${each.key}"
  policy   = each.value
}

resource "aws_iam_role_policy_attachment" "task_role_policy_attach" {
  for_each   = var.task_customer_managed_policies
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_policy[each.key].arn
}

# aws managed policy
resource "aws_iam_role_policy_attachment" "task_role_policy_attach_aws_managed" {
  for_each   = toset(var.task_aws_managed_policies)
  role       = aws_iam_role.task_role.name
  policy_arn = each.value
}

# service_linked_role
resource "aws_iam_service_linked_role" "ecs_service_linked_role" {
  count            = var.service_linked_role_created ? 1 : 0
  aws_service_name = "ecs.amazonaws.com"
}

data "aws_iam_role" "ecs_service_linked_role" {
  count = var.service_linked_role_created ? 0 : 1
  name  = "AWSServiceRoleForECS"
}

# lb
resource "aws_lb" "lb" {
  name               = var.alb_name
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups    = var.security_groups
  subnets            = var.subnets

  enable_deletion_protection = var.enable_deletion_protection

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  #   tags = {
  #     Environment = "production"
  #   }
}

# target_group
resource "aws_lb_target_group" "tg" {
  name        = "${var.target_group_name}-${substr(uuid(), 0, 3)}"
  port        = var.target_group_port
  protocol    = var.target_group_protocol
  vpc_id      = var.target_group_vpc_id
  target_type = var.launch_type == "FARGATE" ? "ip" : var.target_type
  health_check {
    enabled             = var.health_check_enabled
    interval            = var.health_check_interval
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = var.health_check_matcher
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}

# lb_listener
resource "aws_lb_listener" "listener" {
  for_each          = var.listener
  load_balancer_arn = aws_lb.lb.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# lb_listener_rule
resource "aws_lb_listener_rule" "listener_rule" {
  for_each     = var.listener
  listener_arn = aws_lb_listener.listener[each.key].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# cloudwatch_log_group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = var.retention_in_days
  tags = {
    Name = var.cloudwatch_log_group_name
  }
}
