# IAM Role
module "IAM_Role" {
  source                     = "../../../modules/IAM/Role"
  role_name                  = "GithubActionsRole"
  trusted_entity_aws_service = false
  custom_assume_role_policy  = data.aws_iam_policy_document.github_actions.json

  policies = local.policies
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # https://qiita.com/minamijoyo/items/eac99e4b1ca0926c4310
  # https://zenn.dev/yukin01/articles/github-actions-oidc-provider-terraform
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}
