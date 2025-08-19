resource "aws_api_gateway_rest_api" "rag_be_api" {
  name = "rag-be-api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  put_rest_api_mode = "merge"
}

resource "aws_api_gateway_resource" "rag_be_api" {
  path_part   = "resource"
  parent_id   = aws_api_gateway_rest_api.rag_be_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.rag_be_api.id
}

resource "aws_api_gateway_method" "rag_be_api" {
  rest_api_id   = aws_api_gateway_rest_api.rag_be_api.id
  resource_id   = aws_api_gateway_resource.rag_be_api.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_deployment" "rag_be_api" {
  rest_api_id = aws_api_gateway_rest_api.rag_be_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.rag_be_api,
      aws_api_gateway_method.rag_be_api,
      aws_api_gateway_integration.rag_be_api,
      aws_api_gateway_rest_api.rag_be_api,
      aws_api_gateway_method_response.cors,
      aws_api_gateway_integration_response.cors,
      aws_api_gateway_method.cors,
      aws_api_gateway_integration.cors,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "rag_be_api" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.rag_be_api.id
  deployment_id = aws_api_gateway_deployment.rag_be_api.id
}

resource "aws_api_gateway_integration" "rag_be_api" {
  rest_api_id             = aws_api_gateway_rest_api.rag_be_api.id
  resource_id             = aws_api_gateway_resource.rag_be_api.id
  http_method             = aws_api_gateway_method.rag_be_api.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.answer_user_query.invoke_arn
}

resource "aws_lambda_permission" "answer_user_query" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.answer_user_query.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:ap-northeast-1:${data.aws_caller_identity.current.id}:${aws_api_gateway_rest_api.rag_be_api.id}/*/${aws_api_gateway_method.rag_be_api.http_method}${aws_api_gateway_resource.rag_be_api.path}"
}

# CORS
resource "aws_api_gateway_method" "cors" {
  rest_api_id   = aws_api_gateway_rest_api.rag_be_api.id
  resource_id   = aws_api_gateway_resource.rag_be_api.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "cors" {
  rest_api_id = aws_api_gateway_rest_api.rag_be_api.id
  resource_id = aws_api_gateway_resource.rag_be_api.id
  http_method = aws_api_gateway_method.cors.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_integration_response" "cors" {
  rest_api_id = aws_api_gateway_rest_api.rag_be_api.id
  resource_id = aws_api_gateway_resource.rag_be_api.id
  http_method = aws_api_gateway_method.cors.http_method
  status_code = aws_api_gateway_method_response.cors.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS'"
  }
}

resource "aws_api_gateway_integration" "cors" {
  rest_api_id = aws_api_gateway_rest_api.rag_be_api.id
  resource_id = aws_api_gateway_resource.rag_be_api.id
  http_method = aws_api_gateway_method.cors.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}