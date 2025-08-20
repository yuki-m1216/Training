# Rule
resource "aws_cloudwatch_event_rule" "rule" {
  provider            = aws.alternate
  name                = var.rule_name
  description         = var.rule_description
  event_pattern       = var.event_pattern
  schedule_expression = var.schedule_expression
  state               = var.state
  event_bus_name      = var.create_event_bus == false ? null : aws_cloudwatch_event_bus.eventbus[0].name
  tags                = var.rule_tags
}

# Target
resource "aws_cloudwatch_event_target" "target" {
  provider       = aws.alternate
  rule           = aws_cloudwatch_event_rule.rule.name
  target_id      = var.target_id
  arn            = var.target_arn
  role_arn       = var.target_role_arn
  event_bus_name = var.create_event_bus == false ? null : aws_cloudwatch_event_bus.eventbus[0].name
  input          = var.input
  input_path     = var.input_path
  dynamic "input_transformer" {
    for_each = var.input_transformer_input_template == null ? [] : [1]
    content {
      input_paths    = var.input_transformer_input_paths
      input_template = var.input_transformer_input_template
    }
  }
}

# EventBus
resource "aws_cloudwatch_event_bus" "eventbus" {
  provider = aws.alternate
  count    = var.create_event_bus ? 1 : 0
  name     = var.event_bus_name
}
