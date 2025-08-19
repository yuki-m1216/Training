# cloudfront
module "cloudfront" {
  source = "../../../modules/CloudFront"

  # distribution
  origin = [{
    domain_name              = module.ecs_fargate.lb_dns_name
    origin_access_control_id = null
    origin_id                = module.ecs_fargate.lb_arn
    origin_path              = null
    custom_origin_config = [{
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = [
        "TLSv1", "TLSv1.1", "TLSv1.2"
      ]
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
    }]
    custom_header       = null
    origin_shield       = null
    connection_attempts = 3
    connection_timeout  = 10
    }
  ]

  default_cache_behavior = [{
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    target_origin_id           = module.ecs_fargate.lb_arn
    cache_policy_id            = null
    origin_request_policy_id   = null
    response_headers_policy_id = null
  }]

  /*
  CloudFrontのデフォルトの証明書を利用する場合
    viewer_certificate = [{
      cloudfront_default_certificate = true
      acm_certificate_arn            = null
      minimum_protocol_version       = null
      ssl_support_method             = null
    }]

  ユーザー発行の証明書を利用する場合
    viewer_certificate = [{
      cloudfront_default_certificate = false
      acm_certificate_arn            = data.terraform_remote_state.acm_us_east_1.outputs.acm_certificate_validation_certificate_us_east_1.aws_acm_certificate_validation_certificate_arn
      minimum_protocol_version       = "TLSv1.2_2021"
      ssl_support_method             = "sni-only"
    }]
  */

  viewer_certificate = [{
    cloudfront_default_certificate = true
    acm_certificate_arn            = null
    minimum_protocol_version       = null
    ssl_support_method             = null
  }]

}


# ECS
module "ecs_fargate" {
  source = "../../../modules/ECS"
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

  # aws managed policy
  execution_aws_managed_policies = [
    data.aws_iam_policy.ecs_task_execution_role_policy.arn,
  ]

  # task_role
  # create customer managed policy
  task_customer_managed_policies = {
    test-policy-01 = file("${path.root}/policies/test-policy-01.json"),
  }

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
  source         = "../../../modules/SecurityGroup"
  sg_name        = "test_ecs_security_group_01"
  sg_description = "test_ecs_security_group_01"
  sg_vpc_id      = "vpc-05b5aeed5c9d8e83e"

  sg_rule = {
    "ingress_01" = {
      type                     = "ingress"
      to_port                  = 80
      from_port                = 80
      protocol                 = "tcp"
      source_security_group_id = module.sg_lb.sg_id
      cidr_blocks              = null
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
      cidr_blocks              = null
      prefix_list_ids          = [data.aws_ec2_managed_prefix_list.cloudfront.id]
      description              = "HTTP from CloudFront"
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
