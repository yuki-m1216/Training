module "route53" {
  source = "../../modules/Route53"

  create_hostzone = true
  hostzone_name   = "yuki-m.com"
}
