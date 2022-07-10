# launch_template
resource "aws_launch_template" "launch_template" {
  name_prefix   = var.name_prefix
  image_id      = var.image_id
  instance_type = var.instance_type
}


output "aws_launch_template_id" {
    value = aws_launch_template.launch_template.id
}
