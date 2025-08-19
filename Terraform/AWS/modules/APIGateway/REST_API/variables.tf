# aws_api_gateway_rest_api
variable "rest_api_name" {
  type        = string
  description = "Name of the REST API."
}

variable "rest_api_body" {
  type        = string
  description = "OpenAPI specification that defines the set of routes and integrations to create as part of the REST API."
}

variable "endpoint_configuration_types" {
  type        = list(string)
  description = "List of endpoint types. This resource currently only supports managing a single value. Valid values: EDGE, REGIONAL or PRIVATE."
  default     = ["REGIONAL"]
}

variable "disable_execute_api_endpoint" {
  type        = bool
  description = "Whether clients can invoke your API by using the default execute-api endpoint."
  default     = false
}

# cloudwatch logging
variable "retention_in_days" {
  type        = number
  description = "The number of days log events are kept in CloudWatch Logs."
  default     = 30
}

# access log
variable "create_access_log" {
  type        = bool
  description = "Whether to enable access logging for the API Gateway."
  default     = false

}

variable "access_log_name" {
  type        = string
  description = "Name of the access log group."
  default     = null
}

variable "access_log_retention_in_days" {
  type        = number
  description = "The number of days log events are kept in CloudWatch Logs."
  default     = 30
}

# aws_api_gateway_method_settings
variable "cloudwatch_log_level" {
  type        = string
  description = <<-EOF
    Logging level for this method, which effects the log entries pushed to Amazon CloudWatch Logs.
    The available levels are OFF, ERROR, and INFO.
  EOF
  default     = "OFF"
}

variable "metrics_enabled" {
  type        = bool
  description = "Whether data trace logging is enabled for this method."
  default     = false
}

variable "data_trace_enabled" {
  type        = bool
  description = "Whether data trace logging is enabled for this method, which effects the log entries pushed to Amazon CloudWatch Logs."
  default     = false
}

variable "access_log_format" {
  type        = string
  description = <<-EOF
  Formatting and values recorded in the logs. 
  For more information on configuring the log format rules visit the AWS documentation
  https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html
  EOF
  default     = <<-EOF
  {
  "requestId":"$context.requestId",
  "extendedRequestId":"$context.extendedRequestId",
  "ip": "$context.identity.sourceIp",
  "caller":"$context.identity.caller",
  "user":"$context.identity.user",
  "userAgent":"$context.identity.userAgent",
  "requestTime":"$context.requestTime",
  "httpMethod":"$context.httpMethod",
  "resourcePath":"$context.resourcePath",
  "status":"$context.status",
  "protocol":"$context.protocol",
  "responseLength":"$context.responseLength",
  "wafResponseCode":"$context.wafResponseCode"
  }
  EOF
}

# aws_api_gateway_stage
variable "stage_name" {
  type        = string
  description = "Name of the stage"
}

# aws_api_gateway_rest_api_policy
variable "create_api_policy" {
  type        = bool
  description = "whether create resouce policy"
  default     = false
}

variable "api_policy" {
  type        = string
  description = "JSON formatted policy document that controls access to the API Gateway."
  default     = null
}

# aws_api_gateway_domain_name
variable "create_domain_name" {
  type        = bool
  description = "whether create custom domain name for use with AWS API Gateway"
  default     = false
}

variable "domain_name" {
  type        = string
  description = "Fully-qualified domain name to register."
  default     = null
}

variable "regional_certificate_arn" {
  type        = string
  description = "ARN for an AWS-managed certificate. Used when a regional domain name is desired."
  default     = null
}

# aws_api_gateway_usage_plan
variable "usage_plan_name" {
  type        = string
  description = "Name of the usage plan."
  default     = null
}

variable "usage_plan_description" {
  type        = string
  description = "Description of the usage plan."
  default     = null
}

variable "quota_settings" {
  type = list(object({
    limit  = number
    offset = number
    period = string
  }))
  description = "Map of quota settings for the usage plan."
  default     = []
}

# aws_api_gateway_api_key
variable "api_key_name" {
  type        = string
  description = "Name of the API key."
  default     = null
}
