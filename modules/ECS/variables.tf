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

variable "network_mode" {
  type        = string
  description = "Docker networking mode to use for the containers in the task."
  default     = "bridge"
}

variable "cpu" {
  type           = number
  desdescription = "Number of cpu units used by the task."
  default        = 256
}

variable "memory" {
  type        = number
  description = "Amount (in MiB) of memory used by the task."
  default     = 512
}

variable "container_definitions" {
  type        = map(any)
  description = "A list of valid container definitions provided as a single valid JSON document."
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

# IAM
# execution_role
variable "execution_role_policy" {
  type        = map(any)
  description = "Policy for TaskExecutionRole"
}

# task_role
variable "task_role_policy" {
  type        = map(any)
  description = "Policy for TaskRole"
}

# service_linked_role
variable "service_linked_role_created" {
  type        = bool
  description = "Whether ECS Service Linked Role already created."
  default     = true
}
