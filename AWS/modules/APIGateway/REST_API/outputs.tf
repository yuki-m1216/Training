# aws_api_gateway_rest_api
output "apigateway_execution_arn" {
  value = aws_api_gateway_rest_api.main.execution_arn
}

# aws_api_gateway_domain_name
output "apigateway_domain_name_regional_domain_name" {
  value = try(aws_api_gateway_domain_name.main[0].regional_domain_name, null)
}

output "apigateway_domain_name_regional_zone_id" {
  value = try(aws_api_gateway_domain_name.main[0].regional_zone_id, null)
}
