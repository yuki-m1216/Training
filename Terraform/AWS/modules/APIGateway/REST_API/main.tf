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

resource "aws_cloudwatch_log_group" "main" {
  count = var.cloudwatch_log_level != "OFF" ? 1 : 0

  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.main.id}/${var.stage_name}"
  retention_in_days = var.retention_in_days
}

resource "aws_cloudwatch_log_group" "access_log" {
  count = var.create_access_log ? 1 : 0

  name              = var.access_log_name != null ? var.access_log_name : "API-Gateway-Access-Logs_${aws_api_gateway_rest_api.main.id}/${var.stage_name}"
  retention_in_days = var.access_log_retention_in_days
}

resource "aws_api_gateway_method_settings" "path_specific" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    logging_level      = var.cloudwatch_log_level
    metrics_enabled    = var.metrics_enabled
    data_trace_enabled = var.data_trace_enabled
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name

  dynamic "access_log_settings" {
    for_each = var.create_access_log ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.access_log[0].arn
      format          = replace(var.access_log_format, "\n", "")
    }
  }
  depends_on = [aws_cloudwatch_log_group.access_log[0]]
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

resource "aws_api_gateway_usage_plan" "main" {
  count = var.usage_plan_name != null ? 1 : 0

  name        = var.usage_plan_name
  description = var.usage_plan_description

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  dynamic "quota_settings" {
    for_each = var.quota_settings
    content {
      limit  = quota_settings.value.limit
      offset = quota_settings.value.offset
      period = quota_settings.value.period
    }
  }

  tags = {
    Name = var.usage_plan_name
  }
}

resource "aws_api_gateway_api_key" "main" {
  count = var.api_key_name != null ? 1 : 0

  name = var.api_key_name
}

resource "aws_api_gateway_usage_plan_key" "main" {
  count = var.api_key_name != null && var.usage_plan_name != null ? 1 : 0

  key_id        = aws_api_gateway_api_key.main[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main[0].id
}
