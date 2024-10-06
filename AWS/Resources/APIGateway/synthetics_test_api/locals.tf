locals {
  create_policies = {
    "InvokeLambda" = data.aws_iam_policy_document.invokelambda.json,
  }
  Lambdapolicies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}
