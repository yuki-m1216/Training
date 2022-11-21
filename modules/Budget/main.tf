# variable 
# sns topic
variable "dudget_name" {}
variable "budget_type" {}
variable "limit_amount" {}
variable "time_unit" {}
variable "threshold" {}
variable "subscriber_sns_topic_arns" {
  type = list(string)
}

# budget
resource "aws_budgets_budget" "Budget" {
  name         = var.dudget_name
  budget_type  = var.budget_type
  limit_amount = var.limit_amount
  limit_unit   = "USD"
  # time_period_end   = "2087-06-15_00:00"
  # time_period_start = "2017-07-01_00:00"
  time_unit = var.time_unit

  # cost_filter {
  #   name = "Service"
  #   values = [
  #     "Amazon Elastic Compute Cloud - Compute",
  #   ]
  # }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = var.threshold
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = var.subscriber_sns_topic_arns
  }
}