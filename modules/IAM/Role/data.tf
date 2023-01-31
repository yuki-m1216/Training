# Assume Role Policy
data "aws_iam_policy_document" "assume_role_policy" {
  count = var.trusted_entity_aws_service ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.identifiers]
    }
  }
}
