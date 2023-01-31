data "aws_caller_identity" "current" {}

# IAM Policy Document
data "aws_iam_policy_document" "test_policy" {
  statement {
    actions = [
      "ec2:*"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "test_policy_2" {
  statement {
    actions = [
      "ec2:*"
    ]
    resources = ["*"]
  }
}
