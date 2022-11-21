# variable 
# sns topic
variable "topic_name" {}
variable "display_name" {}

# sns topic policy
variable "policy" {}

#sns subscription email
variable "endpoint" {}

# sns topic
resource "aws_sns_topic" "sns_topic" {
  name         = var.topic_name
  display_name = var.display_name
}

# sns topic policy
resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.sns_topic.arn
  policy = var.policy
}

#sns subscription email
resource "aws_sns_topic_subscription" "subscription_email" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "email"
  endpoint  = var.endpoint
}
