# launch_template
variable "name_prefix" {}
variable "image_id" {}
variable "instance_type" {}
variable "user_data" {
  default = null
}
variable "vpc_security_group_ids" {
  type    = list(any)
  default = null
}

# autoscaling_group
variable "autoscaling_group_name" {}
variable "vpc_zone_identifier" {
  type = list(any)
}
variable "desired_capacity" {}
variable "max_size" {}
variable "min_size" {}
variable "launch_template_version" {
  type    = string
  default = "$Latest"
}

# lb
variable "alb_name" {}

variable "internal" {
  type    = bool
  default = false
}

variable "load_balancer_type" {
  type    = string
  default = "application"
}

variable "security_groups" {
  type = list(string)
}

variable "subnets" {
  type = list(string)
}

variable "enable_deletion_protection" {
  type    = bool
  default = false
}

# target_group
variable "target_group_name" {
  type = string
}

variable "target_group_port" {
  type    = number
  default = 80
}

variable "target_group_protocol" {
  type    = string
  default = "HTTP"
}

variable "target_group_vpc_id" {
  type = string
}

variable "target_type" {
  type    = string
  default = "instance"
}

variable "health_check_interval" {
  type    = number
  default = 30
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "health_check_port" {
  type    = any
  default = "traffic-port"
}

variable "health_check_protocol" {
  type    = string
  default = "HTTP"
}

variable "health_check_timeout" {
  type    = number
  default = 5
}

variable "health_check_healthy_threshold" {
  type    = number
  default = 3
}

variable "health_check_unhealthy_threshold" {
  type    = number
  default = 3
}

variable "health_check_matcher" {
  type    = string
  default = "200"
}
