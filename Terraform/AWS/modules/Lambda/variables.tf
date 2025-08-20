# Lambda
variable "lambda_filename" {}
variable "lambda_function_name" {}
variable "lambda_role" {
  default = null
}
variable "handler" {}
variable "runtime" {}
variable "environment_variables" {
  type    = map(any)
  default = null
}

# Lambda permission
variable "create_lambda_permission" {
  type        = bool
  description = "whether create lambda permissions"
  default     = true
}

variable "statement_id" {
  default = null
}
variable "principal" {
  default = null
}
variable "source_arn" {
  default = null
}

# CloudWatch Logs
variable "log_group_retention_in_days" {
  type        = number
  description = <<-EOT
  Specifies the number of days you want to retain log events in the specified log group.
  Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 
  1827, 2192, 2557, 2922, 3288, 3653, and 0.
  EOT
  default     = 30
}
