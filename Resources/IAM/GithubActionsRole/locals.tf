locals {
  allowed_github_repositories = [
    "Terraform",
  ]
  github_org_name = "y-mitsuyama1216"
  full_paths = [
    for repo in local.allowed_github_repositories : "repo:${local.github_org_name}/${repo}:*"
  ]
}

locals {
  policies = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
}
