module "apigateway" {
  source = "../../../modules/APIGateway/REST_API"

  # aws_api_gateway_rest_api
  rest_api_name                = "REST-API"
  rest_api_body                = data.template_file.openapi.rendered
  disable_execute_api_endpoint = true

  # aws_api_gateway_stage
  stage_name = "dev"

  # aws_api_gateway_rest_api_policy
  create_api_policy = true
  api_policy        = data.aws_iam_policy_document.apigateway_policy.json

  # aws_api_gateway_domain_name
  create_domain_name       = true
  domain_name              = "apigateway.yuki-m.com"
  regional_certificate_arn = data.terraform_remote_state.acm_ap_northeast_1.outputs.acm_certificate_validation_certificate_arn_ap_northeast_1.aws_acm_certificate_validation_certificate_arn
}

module "route53_apigateway_record" {
  source = "../../../modules/Route53"

  create_record = true
  zone_id       = data.terraform_remote_state.hoste_zone_id.outputs.hoste_zone_id
  record_name   = "apigateway.yuki-m.com"
  type          = "A"
  alias = [{
    name                   = module.apigateway.apigateway_domain_name_regional_domain_name
    zone_id                = module.apigateway.apigateway_domain_name_regional_zone_id
    evaluate_target_health = false
  }]
}

module "iam_for_apigateway" {
  source          = "../../../modules/IAM/Role"
  role_name       = "APIGatewayInvokeLambda"
  identifiers     = "apigateway.amazonaws.com"
  create_policies = local.create_policies
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
