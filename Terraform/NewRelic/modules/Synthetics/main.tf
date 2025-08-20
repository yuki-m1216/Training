resource "newrelic_synthetics_script_monitor" "this" {
  status           = var.script_monitor_status
  name             = var.script_monitor_name
  type             = var.script_monitor_type
  locations_public = var.script_monitor_locations_public
  period           = var.script_monitor_period

  script = var.script_monitor_script

  script_language      = "JAVASCRIPT"
  runtime_type         = var.script_monitor_runtime_type
  runtime_type_version = var.script_monitor_runtime_type_version

  dynamic "tag" {
    for_each = var.script_monitor_tag
    content {
      key    = tag.value.key
      values = tag.value.values

    }
  }
}