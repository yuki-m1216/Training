module "apigateway" {
  source = "../../../modules/APIGateway/REST_API"

  # aws_api_gateway_rest_api
  rest_api_name                = "Synthetics-Test-API"
  rest_api_body                = data.template_file.openapi.rendered

  # aws_api_gateway_stage
  stage_name = "dev"

  # usage plan
  usage_plan_name        = "Synthetics-Test-Usage-Plan"
  usage_plan_description = "Synthetics Test Usage Plan"
  quota_settings = [{
    limit  = 3000
    offset = null
    period = "DAY"
  }]

  # api_gateway_api_key
  api_key_name = "Synthetics-Test-API-Key"
}

module "lambda" {
  source = "../../../modules/Lambda"

  providers = {
    aws.alternate = aws
  }

  lambda_function_name     = "Synthetics-Test-Lambda"
  runtime                  = "nodejs20.x"
  handler                  = "index.handler"
  lambda_filename          = data.archive_file.function.output_path
  lambda_role              = module.iam_for_lambda.role_arn

  create_lambda_permission = true
  statement_id = "AllowExecutionFromAPIGateway"
  principal    = "apigateway.amazonaws.com"
  source_arn   = module.apigateway.apigateway_execution_arn
}

module "iam_for_lambda" {
  source      = "../../../modules/IAM/Role"
  role_name   = "Synthetics-Test-Lambda-Role"
  identifiers = "lambda.amazonaws.com"
  policies    = local.Lambdapolicies
}

