resource "aws_api_gateway_rest_api" "main" {
  name = var.rest_api_name
  body = var.rest_api_body

  endpoint_configuration {
    types = var.endpoint_configuration_types
  }

  disable_execute_api_endpoint = var.disable_execute_api_endpoint

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
      aws_api_gateway_rest_api.main.disable_execute_api_endpoint,
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

resource "aws_api_gateway_domain_name" "main" {
  count = var.create_domain_name ? 1 : 0

  domain_name              = var.domain_name
  regional_certificate_arn = var.regional_certificate_arn

  endpoint_configuration {
    types = var.endpoint_configuration_types
  }

}

resource "aws_api_gateway_base_path_mapping" "main" {
  count = var.create_domain_name ? 1 : 0

  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = try(aws_api_gateway_domain_name.main[0].domain_name, null)
}
