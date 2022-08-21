# launch_template
variable "name_prefix" {}
variable "image_id" {}
variable "instance_type" {}
variable "user_data" {
    default = null
}
variable "vpc_security_group_ids" {
  type = list
  default = null
}

# autoscaling_group
variable "autoscaling_group_name" {}
variable "vpc_zone_identifier" {
    type = list
}
variable "desired_capacity" {}
variable "max_size" {}
variable "min_size" {}
variable "launch_template_version" {
    type = string
    default = "$Latest"
}
