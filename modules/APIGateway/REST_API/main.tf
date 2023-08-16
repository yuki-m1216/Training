resource "aws_api_gateway_rest_api" "main" {
  name = var.rest_api_name
  body = var.rest_api_body

  endpoint_configuration {
    types = var.endpoint_configuration_types
  }

  lifecycle {
    ignore_changes = [
      policy
    ]
  }
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.main.body,
      var.create_api_policy ? var.api_policy : null,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name
}

resource "aws_api_gateway_rest_api_policy" "main" {
  count = var.create_api_policy ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id
  policy      = var.api_policy
}
