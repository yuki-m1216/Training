# OpenSearchServerlessにアクセスするIAMロールを作成する
resource "aws_iam_role" "opensearch_access_role" {
  name = "opensearch-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
# OpenSearchServerlessにアクセスするIAMポリシーを作成する
resource "aws_iam_policy" "opensearch_access_policy" {
  name        = "opensearch-access-policy"
  description = "opensearch-access-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "aoss:*",
        Resource = "*"
      }
    ]
  })
}
# OpenSearchServerlessにアクセスするIAMロールにポリシーをアタッチする
resource "aws_iam_role_policy_attachment" "opensearch_access_role_policy_attachment" {
  role       = aws_iam_role.opensearch_access_role.name
  policy_arn = aws_iam_policy.opensearch_access_policy.arn
}