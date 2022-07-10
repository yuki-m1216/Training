# launch_template
variable "name_prefix" {}
variable "image_id" {}
variable "instance_type" {}

# autoscaling_group
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
