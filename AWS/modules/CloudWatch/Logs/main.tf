resource "aws_cloudwatch_log_group" "main" {
  name              = var.log_group_name
  retention_in_days = var.log_group_retention_in_days

  tags = {
    Name = var.log_group_name
  }
}

resource "aws_cloudwatch_log_stream" "main" {
  count = var.create_log_stream ? 1 : 0

  name           = var.log_stream_name
  log_group_name = aws_cloudwatch_log_group.main.name
}

resource "aws_cloudwatch_log_subscription_filter" "main" {
  count = var.create_subscription_filter ? 1 : 0

  name            = var.subscription_filter_name
  role_arn        = var.subscription_filter_role_arn
  log_group_name  = aws_cloudwatch_log_group.main.name
  filter_pattern  = var.filter_pattern
  destination_arn = var.destination_arn
  distribution    = var.distribution
}
