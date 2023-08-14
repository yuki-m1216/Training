module "acm" {
  source = "../../modules/ACM"

  providers = {
    aws.alternate = aws
  }

  domain_name               = "yuki-m.com"
  subject_alternative_names = ["*.yuki-m.com"]
}

module "acm_use1" {
  source = "../../modules/ACM"

  providers = {
    aws.alternate = aws.us-east-1
  }

  domain_name               = "yuki-m.com"
  subject_alternative_names = ["*.yuki-m.com"]
}
