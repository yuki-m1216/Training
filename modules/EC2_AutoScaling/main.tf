# launch_template
resource "aws_launch_template" "launch_template" {
  name_prefix   = var.name_prefix
  image_id      = var.image_id
  instance_type = var.instance_type
}

# autoscaling_group
resource "aws_autoscaling_group" "autoscaling_group" {
  vpc_zone_identifier = var.vpc_zone_identifier
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = var.launch_template_version
  }
}


output "aws_launch_template_id" {
    value = aws_launch_template.launch_template.id
}

output "aws_autoscaling_group_id" {
    value = aws_autoscaling_group.autoscaling_group.id
}
