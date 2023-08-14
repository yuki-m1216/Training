module "route53" {
  source = "../../modules/Route53"

  hostzone_name = "yuki-m.com"
}
