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
}
