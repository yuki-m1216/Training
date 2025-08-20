output "RuleArn" {
  value = aws_cloudwatch_event_rule.rule.arn
}

output "Eventbridge_Eventbus_Arn" {
  value = aws_cloudwatch_event_bus.eventbus[*].arn
}
