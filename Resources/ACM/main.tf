module "acm" {
  source = "../../modules/ACM"

  domain_name               = "yuki-m.com"
  subject_alternative_names = ["*.yuki-m.com"]
}

