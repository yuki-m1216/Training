module "apigateway" {
  source = "../../../modules/APIGateway/REST_API"

  # aws_api_gateway_rest_api
  rest_api_name                = "Synthetics-Test-API"
  rest_api_body                = data.template_file.openapi.rendered
  disable_execute_api_endpoint = true

  # aws_api_gateway_stage
  stage_name = "dev"

}

module "lambda" {
  source = "../../../modules/Lambda"

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
  source      = "../../../modules/IAM/Role"
  role_name   = "TestAPIGatewayLambda"
  identifiers = "lambda.amazonaws.com"
  policies    = local.Lambdapolicies
}
