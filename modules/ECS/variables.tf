# ecs_cluster
variable "cluster_name" {
  type        = string
  description = "Name of the cluster (up to 255 letters, numbers, hyphens, and underscores)."
}

variable "containerInsights" {
  type        = bool
  description = "Using Container Insights."
  default     = false
}

# ecs_task_definition
variable "family" {
  type        = string
  description = "A unique name for your task definition."
}

variable "requires_compatibilities" {
  type        = string
  description = "Set of launch types required by the task. The valid values are EC2 and FARGATE."
  default     = "FARGATE"
}

variable "container_definitions" {
  type        = any
  description = "A list of valid container definitions provided as a single valid JSON document."
}

variable "network_mode" {
  type        = string
  description = "Docker networking mode to use for the containers in the task."
  default     = "bridge"
}

variable "cpu" {
  type        = number
  description = "Number of cpu units used by the task."
  default     = 256
}

variable "memory" {
  type        = number
  description = "Amount (in MiB) of memory used by the task."
  default     = 512
}

variable "operating_system_family" {
  type        = string
  description = "If the requires_compatibilities is FARGATE this field is required."
  default     = "LINUX"
}

variable "cpu_architecture" {
  type        = string
  description = "Must be set to either X86_64 or ARM64"
  default     = "X86_64"
}

# ecs_service
variable "service_name" {
  type        = string
  description = "Name of the service."
}

variable "desired_count" {
  type        = number
  description = "Number of instances of the task definition to place and keep running."
  default     = 1
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "Lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment."
  default     = 100
}

variable "deployment_maximum_percent" {
  type        = number
  description = "Upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment."
  default     = 200
}

variable "enable_execute_command" {
  type        = bool
  description = "Specifies whether to enable Amazon ECS Exec for the tasks within the service."
  default     = true
}

variable "launch_type" {
  type        = string
  description = "Launch type on which to run your service."
  default     = "FARGATE"
}

variable "platform_version" {
  type        = string
  description = "Platform version on which to run your service."
  default     = "LATEST"
}

variable "assign_public_ip" {
  type        = bool
  description = "Assign a public IP address to the ENI (Fargate launch type only)."
  default     = false
}

variable "service_subnets" {
  type        = list(string)
  description = " Subnets associated with the task or service."
}

variable "service_security_groups" {
  type        = list(string)
  description = "Security groups associated with the task or service."
}

variable "propagate_tags" {
  type        = string
  description = "Specifies whether to propagate the tags from the task definition or the service to the tasks. The valid values are SERVICE and TASK_DEFINITION."
  default     = null
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647."
  default     = 60
}

variable "deployment_controller_type" {
  type        = string
  description = "Type of deployment controller. Valid values: CODE_DEPLOY, ECS, EXTERNAL."
  default     = "ECS"
}

variable "circuit_breaker_deployment_enabled" {
  type        = bool
  description = "Whether to enable the deployment circuit breaker logic for the service."
  default     = true
}

variable "circuit_breaker_rollback_enabled" {
  type        = bool
  description = "Whether to enable Amazon ECS to roll back the service if a service deployment fails."
  default     = true
}

variable "container_name" {
  type        = string
  description = "Name of the container to associate with the load balancer (as it appears in a container definition)."
}

variable "container_port" {
  type        = number
  description = "Port on the container to associate with the load balancer."
}

# IAM
# execution_role
variable "execution_customer_managed_policies" {
  type        = map(any)
  description = "Customer Managed Policy for TaskExecutionRole"
  default     = {}
}

variable "execution_aws_managed_policies" {
  type        = list(string)
  description = "AWS Managed Policy for TaskExecutionRole"
  default     = []
}

# task_role
variable "task_customer_managed_policies" {
  type        = map(any)
  description = "Customer Managed Policy for TaskRole"
  default     = {}
}

variable "task_aws_managed_policies" {
  type        = list(string)
  description = "AWS Managed Policy for TaskRole"
  default     = []
}

# service_linked_role
variable "service_linked_role_created" {
  type        = bool
  description = "Whether ECS Service Linked Role already created."
  default     = true
}

# lb
variable "alb_name" {
  type        = string
  description = "The name of the LB."
}

variable "internal" {
  type        = bool
  description = "If true, the LB will be internal."
  default     = false
}

variable "load_balancer_type" {
  type        = string
  description = "The type of load balancer to create."
  default     = "application"
}

variable "security_groups" {
  type        = list(string)
  description = "A list of security group IDs to assign to the LB."
}

variable "subnets" {
  type        = list(string)
  description = "A list of subnet IDs to attach to the LB."
}

variable "enable_deletion_protection" {
  type        = bool
  description = "If true, deletion of the load balancer will be disabled via the AWS API."
  default     = false
}

# target_group
variable "target_group_name" {
  type        = string
  description = "Name of the target group. If omitted, Terraform will assign a random, unique name."
}

variable "target_group_port" {
  type        = number
  description = "Port on which targets receive traffic, unless overridden when registering a specific target."
  default     = 80
}

variable "target_group_protocol" {
  type        = string
  description = "Protocol to use for routing traffic to the targets."
  default     = "HTTP"
}

variable "target_group_vpc_id" {
  type        = string
  description = "Identifier of the VPC in which to create the target group."
}

variable "target_type" {
  type        = string
  description = "Type of target that you must specify when registering targets with this target group."
  default     = "instance"
}


variable "health_check_enabled" {
  type        = bool
  description = "Whether health checks are enabled."
  default     = true
}
variable "health_check_interval" {
  type        = number
  description = "Approximate amount of time, in seconds, between health checks of an individual target."
  default     = 30
}

variable "health_check_path" {
  type        = string
  description = "Destination for the health check request."
  default     = "/"
}

variable "health_check_port" {
  type        = any
  description = "Port to use to connect with the target."
  default     = "traffic-port"
}

variable "health_check_protocol" {
  type        = string
  description = "Protocol to use to connect with the target."
  default     = "HTTP"
}

variable "health_check_timeout" {
  type        = number
  description = "Amount of time, in seconds, during which no response means a failed health check."
  default     = 5
}

variable "health_check_healthy_threshold" {
  type        = number
  description = "Number of consecutive health checks successes required before considering an unhealthy target healthy."
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  type        = number
  description = "Number of consecutive health check failures required before considering the target unhealthy."
  default     = 3
}

variable "health_check_matcher" {
  type        = string
  description = "Response codes to use when checking for a healthy responses from a target."
  default     = "200"
}

# lb_listener
variable "listener" {
  type        = map(any)
  description = "Map of Listener and listener Rule"
}
