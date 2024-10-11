module "synthetics_script_monitor" {
  source = "../../modules/Synthetics"

  script_monitor_status           = "ENABLED"
  script_monitor_name             = "synthetics_script_monitor"
  script_monitor_type             = "SCRIPT_API"
  script_monitor_locations_public = ["AWS_AP_NORTHEAST_1"]
  script_monitor_period           = "EVERY_6_HOURS"
  script_monitor_script           = data.local_file.syntheticis_script.content
  script_monitor_runtime_type     = "NODE_API"
  script_monitor_runtime_type_version = "16.10"
}
