terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.alternate ]
    }
  }
}

## variable 
# Rule
variable "rule_name" {}
variable "rule_description" {
  default = null
}
variable "event_pattern" {
  type = string
  default = null
}
variable "schedule_expression" {
  default = null
}
variable "is_enabled" {
  default = true
}
variable "rule_tags" {
  type = map
  default = null
}

# Target
variable "target_id" {
  default = null
}
variable "target_arn" {}
variable "target_role_arn" {
  default = null
}
variable "input" {
  default = null
}
variable "input_path" {
  default = null
}
variable "input_transformer_input_paths" {
  default = null
}
variable "input_transformer_input_template" {
  default = null
}

# EventBus
variable "create_event_bus" {
  default = false
}
variable "event_bus_name" {
  default = null
}


## resource
# Rule
resource "aws_cloudwatch_event_rule" "rule" {
  provider      = aws.alternate
  name        = var.rule_name
  description = var.rule_description
  event_pattern = var.event_pattern
  schedule_expression = var.schedule_expression
  is_enabled = var.is_enabled
  event_bus_name = var.create_event_bus == false ? null : var.event_bus_name
  tags = var.rule_tags
}

# Target
resource "aws_cloudwatch_event_target" "target" {
  provider      = aws.alternate
  rule      = aws_cloudwatch_event_rule.rule.name
  target_id = var.target_id
  arn       = var.target_arn
  role_arn = var.target_role_arn
  event_bus_name = var.create_event_bus == false ? null : var.event_bus_name
  input = var.input
  input_path = var.input_path
  dynamic "input_transformer" {
    for_each = var.input_transformer_input_template == null ? []:[1] 
    content {
    input_paths = var.input_transformer_input_paths
    input_template = var.input_transformer_input_template      
    }
  }
}

# EventBus
resource "aws_cloudwatch_event_bus" "eventbus" {
  provider      = aws.alternate
  count = var.create_event_bus ? 1:0
  name = var.event_bus_name
}

## output
output "RuleArn" {
  value = aws_cloudwatch_event_rule.rule.arn
}

output "Eventbridge_Eventbus_Arn" {
  value = aws_cloudwatch_event_bus.eventbus[*].arn
}