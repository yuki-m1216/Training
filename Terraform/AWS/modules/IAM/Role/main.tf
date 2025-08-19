# IAM Role
resource "aws_iam_role" "iam_role" {
  name               = var.role_name
  assume_role_policy = try(data.aws_iam_policy_document.assume_role_policy[0].json, var.custom_assume_role_policy)

  tags = {
    Name = var.role_name

  }
}

# IAM Policy
resource "aws_iam_policy" "policy" {
  for_each = var.create_policies

  name   = each.key
  policy = each.value
}


# IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "attach" {
  for_each = toset(var.policies)

  role       = aws_iam_role.iam_role.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "attach_create_policies" {
  for_each = aws_iam_policy.policy

  role       = aws_iam_role.iam_role.name
  policy_arn = each.value.arn
}
