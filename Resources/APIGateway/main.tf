module "apigateway" {
  source = "../../modules/APIGateway/REST_API"

  # aws_api_gateway_rest_api
  rest_api_name = "REST-API"
  rest_api_body = data.template_file.openapi.rendered

  # aws_api_gateway_stage
  stage_name = "dev"

  # aws_api_gateway_rest_api_policy
  create_api_policy = true
  api_policy        = data.aws_iam_policy_document.apigateway_policy.json
}

module "iam_for_apigateway" {
  source          = "../../modules/IAM/Role"
  role_name       = "APIGatewayInvokeLambda"
  identifiers     = "apigateway.amazonaws.com"
  create_policies = local.create_policies
}

module "lambda" {
  source = "../../modules/Lambda"

  providers = {
    aws.alternate = aws
  }

  lambda_function_name     = "Test-APIGateway-Lambda"
  runtime                  = "python3.11"
  lambda_filename          = data.archive_file.function.output_path
  handler                  = "main.lambda_handler"
  lambda_role              = module.iam_for_lambda.role_arn
  create_lambda_permission = false
}

module "iam_for_lambda" {
  source      = "../../modules/IAM/Role"
  role_name   = "TestAPIGatewayLambda"
  identifiers = "lambda.amazonaws.com"
  policies    = local.Lambdapolicies
}
