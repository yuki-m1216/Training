module "CloudTrail" {
  source = "../../modules/CloudTrail"
  # trail
  cloudtrailname                = "Main-Trail"
  is_multi_region_trail         = "true"
  include_global_service_events = "true"
  read_write_type               = "All"
  include_management_events     = "true"

  # s3
  bucketname      = "cloudtrail-bucket-ym"
  policy          = data.template_file.policy.rendered
  id              = "cloudtrail-lifecycle"
  expiration_days = 31
  status          = "Enabled"
}
