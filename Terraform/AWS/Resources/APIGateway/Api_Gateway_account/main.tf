resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.main.arn
}

resource "aws_iam_role" "main" {
  name               = "api_gateway_account_cloudwatch_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "main" {
  name   = "api_gateway_account_cloudwatch_policy"
  role   = aws_iam_role.main.id
  policy = data.aws_iam_policy_document.cloudwatch.json
}