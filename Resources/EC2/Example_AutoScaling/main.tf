# launch_template
module "launch_template" {
  source = "../../../modules/EC2_AutoScaling"
  name_prefix = "test_template"
  image_id = "ami-0b7546e839d7ace12"
  instance_type = "t2.micro"
}
output "launch_template" {
  value = module.launch_template
}