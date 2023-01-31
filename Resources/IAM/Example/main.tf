# IAM Role
module "iam_role" {
  source                     = "../../../modules/IAM/Role"
  role_name                  = "TestRole"
  trusted_entity_aws_service = true
  identifiers                = "ec2.amazonaws.com"
  create_policies            = local.create_policies
  policies                   = local.policies
}
