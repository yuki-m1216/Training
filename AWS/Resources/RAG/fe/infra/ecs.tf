# ECS Fargate
resource "aws_ecs_cluster" "this" {
  name = "fe-ecs-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = "fe-ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "fe-ecs-container"
      image     = "${data.aws_caller_identity.current.id}.dkr.ecr.ap-northeast-1.amazonaws.com/my-ecr/rag:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENV"
          value = "dev"
        },
        {
          name  = "NEXT_PUBLIC_API_URL"
          value = "${data.terraform_remote_state.answer_user_query.outputs.api_gateway_invoke_url}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"       = "ap-northeast-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "this" {
  name            = "fe-ecs-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = [
    data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id["private-subnet-1a"],
    data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id["private-subnet-1c"]
    ]
    security_groups  = [aws_security_group.this.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "fe-ecs-container"
    container_port   = 3000
  }
}

# Security Group
resource "aws_security_group" "this" {
  name = "fe-ecs-sg"
  vpc_id = data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  security_group_id = aws_security_group.this.id
  ip_protocol       = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  }

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/fe-ecs-task"
  retention_in_days = 7
}
# Application Load Balancer
resource "aws_lb" "this" {
  name               = "fe-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = [
    data.terraform_remote_state.mainvpc.outputs.mainvpc.public_subnet_id["public-subnet-1a"],
    data.terraform_remote_state.mainvpc.outputs.mainvpc.public_subnet_id["public-subnet-1c"]
  ]
}

# ALB Target Group
resource "aws_lb_target_group" "this" {
  name        = "fe-alb-target-group"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id
  target_type = "ip"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# ALB Listener
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
