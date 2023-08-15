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
