# logs
variable "log_group_name" {
  type        = string
  description = "The name of the log group."
}

variable "log_group_retention_in_days" {
  type        = number
  description = <<EOT
  Specifies the number of days you want to retain log events in the specified log group.
  Possible values are: 
  1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 
  1827, 2192, 2557, 2922, 3288, 3653, and 0.
  EOT
  default     = 0
}

# stream
variable "create_log_stream" {
  type        = bool
  description = "whether create log stream"
  default     = false
}

variable "log_stream_name" {
  type        = string
  description = "The name of the log stream."
  default     = null
}

# subscription filter
variable "create_subscription_filter" {
  type        = bool
  description = "whether create subscription filter"
  default     = false
}

variable "subscription_filter_name" {
  type        = string
  description = "A name for the subscription filter"
  default     = null
}

variable "subscription_filter_role_arn" {
  type        = string
  description = "The ARN of an IAM role that grants Amazon CloudWatch Logs permissions to deliver ingested log events to the destination."
  default     = null
}

variable "filter_pattern" {
  type        = string
  description = "A valid CloudWatch Logs filter pattern for subscribing to a filtered stream of log events."
  default     = ""
}

variable "destination_arn" {
  type        = string
  description = "The ARN of the destination to deliver matching log events to. Kinesis stream or Lambda function ARN."
  default     = null
}

variable "distribution" {
  type        = string
  description = "The method used to distribute log data to the destination."
  default     = "ByLogStream"
}
