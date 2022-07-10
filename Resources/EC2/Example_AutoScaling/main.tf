# EC2_AutoScaling
module "EC2_AutoScaling" {
  source = "../../../modules/EC2_AutoScaling"
  name_prefix = "test_template"
  image_id = "ami-0b7546e839d7ace12"
  instance_type = "t2.micro"
  vpc_zone_identifier = [
    "subnet-0ef3a322300e969c2"
    ]
  desired_capacity = 1
  max_size = 1
  min_size = 1
}
output "EC2_AutoScaling" {
  value = module.EC2_AutoScaling
}