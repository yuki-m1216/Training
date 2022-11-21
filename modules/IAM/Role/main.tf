# variable 
# IAM Role
variable "role_name" {}
variable "create_role" {
  default = false
}

# Assume Role Policy 
variable "identifiers" {}

# IAM Policy
variable "policy_name" {
  default = null
}
variable "policy" {
  default = null
}
variable "create_policy" {
  default = false
}

# IAM Role Policy Attachment
variable "attachment_role_name" {
  default = null
}
# variable "policy_arn" {
#   default = null
# }

variable "policies" {
  # default = null
}

# IAM Role
resource "aws_iam_role" "iam_role" {
  count = var.create_role ? 1 : 0
  name  = var.role_name

  assume_role_policy = data.aws_iam_policy_document.assume-role-policy.json

  tags = {
    Name = var.role_name

  }
}

# Assume Role Policy
data "aws_iam_policy_document" "assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.identifiers]
    }
  }
}


# IAM Policy
resource "aws_iam_policy" "policy" {
  count  = var.create_policy ? 1 : 0
  name   = var.policy_name
  policy = var.policy
}


# IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "attach" {
  # for_each = toset(flatten([
  #   var.policies
  # ]))
  for_each   = { for i in var.policies : i => i }
  role       = var.create_role ? aws_iam_role.iam_role[0].name : var.attachment_role_name
  policy_arn = each.value
}


output "RoleName" {
  value = var.create_role ? aws_iam_role.iam_role[0].name : null
}

output "RoleArn" {
  value = var.create_role ? aws_iam_role.iam_role[0].arn : null
}

output "PolicyArn" {
  value = var.create_policy ? aws_iam_policy.policy[0].arn : null
}