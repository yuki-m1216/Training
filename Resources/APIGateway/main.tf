module "apigateway" {
  source = "../../modules/APIGateway/REST_API"

  # aws_api_gateway_rest_api
  rest_api_name = "REST-API"
  rest_api_body = data.template_file.openapi.rendered

  # aws_api_gateway_stage
  stage_name = "dev"
}

module "iam_for_apigateway" {
  source          = "../../modules/IAM/Role"
  role_name       = "APIGatewayInvokeLambda"
  identifiers     = "apigateway.amazonaws.com"
  create_policies = local.create_policies
}
