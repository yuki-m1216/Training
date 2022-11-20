provider "aws" {
  # access_key = var.access_key
  # secret_key = var.secret_key
  profile = var.profile
  region  = "ap-northeast-1"
}

terraform {
  required_version = ">= 0.13.0"
  backend "s3" {
    bucket  = "s3-terraform-state-y-mitsuyama"
    region  = "ap-northeast-1"
    key     = "IAM.tfstate"
    encrypt = true
  }
}

# IAM Role
module "IAM_Role" {
  source        = "../../../modules/IAM/Role"
  create_role   = true
  role_name     = "TestRole"
  identifiers   = "ec2.amazonaws.com"
  create_policy = true
  policy_name   = "TestPolicy"
  policy        = data.aws_iam_policy_document.TestPolicy.json
  policies      = local.policies
}

locals {
  policies = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/TestPolicy"
  ]
}


data "aws_iam_policy" "LambdaBasicExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# # IAM Policy
# module "IAM_Policy" {
#   source = "../../../modules/IAM/Policy"
#   policy_name = "TestPolicy"
#   policy = data.aws_iam_policy_document.TestPolicy.json 
#   # attachment_role_name = module.IAM_Role.RoleName
# }

# IAM Policy Document
data "aws_iam_policy_document" "TestPolicy" {
  statement {
    actions = [
      "ec2:*"
    ]
    resources = ["*"]
  }
}

locals {
  RoleName = [
    module.IAM_Role.RoleName
    # "TestRole2"
  ]
}


# # IAM Attachment
# module "IAM_Attachment" {
#   source = "../../../modules/IAM/Attachment"
#   for_each = {for i in local.RoleName : i => i}
#   attachment_role_name = each.value
#   policy_arn = module.IAM_Policy.PolicyArn
# }
