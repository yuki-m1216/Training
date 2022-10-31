# launch_template
resource "aws_launch_template" "launch_template" {
  name_prefix            = var.name_prefix
  image_id               = var.image_id
  instance_type          = var.instance_type
  user_data              = var.user_data
  vpc_security_group_ids = var.vpc_security_group_ids
}

# autoscaling_group
resource "aws_autoscaling_group" "autoscaling_group" {
  name                = var.autoscaling_group_name
  vpc_zone_identifier = var.vpc_zone_identifier
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = var.launch_template_version
  }
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
  name        = var.target_group_name
  port        = var.target_group_port
  protocol    = var.target_group_protocol
  vpc_id      = var.target_group_vpc_id
  target_type = var.target_type
  health_check {
    interval            = var.health_check_interval
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = var.health_check_matcher
  }
}

output "aws_launch_template_id" {
  value = aws_launch_template.launch_template.id
}

output "aws_autoscaling_group_id" {
  value = aws_autoscaling_group.autoscaling_group.id
}

output "aws_lb_id" {
  value = aws_lb.lb.id
}
