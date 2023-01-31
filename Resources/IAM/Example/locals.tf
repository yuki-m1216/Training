locals {
  create_policies = {
    "test-policy"  = data.aws_iam_policy_document.test_policy.json,
    "test2-policy" = data.aws_iam_policy_document.test_policy_2.json,
  }

  policies = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  ]
}
