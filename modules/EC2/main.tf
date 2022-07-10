# EC2
resource "aws_instance" "ec2" {
  for_each = var.ec2
  ami           = each.value.ami
  instance_type = each.value.instance_type
  disable_api_stop = each.value.disable_api_stop
  disable_api_termination = each.value.disable_api_termination
  # todo
  # ebs_block_device {
  # }
  ebs_optimized = each.value.ebs_optimized
  iam_instance_profile = each.value.iam_instance_profile
  key_name = each.value.key_name
  monitoring = each.value.monitoring
  private_ip = each.value.private_ip
  vpc_security_group_ids = each.value.vpc_security_group_ids
  subnet_id = each.value.subnet_id
  tags = {
    Name = each.value.ec2_name
  }
  user_data = each.value.user_data

  root_block_device {
    # for_each = var.ec2
    # content{
      delete_on_termination = each.value.delete_on_termination
      encrypted = each.value.encrypted
      iops = each.value.iops
      kms_key_id = each.value.kms_key_id
      tags = {
        Name = each.value.ec2_name
      }
      throughput = each.value.throughput
      volume_size = each.value.volume_size
      volume_type = each.value.volume_type
    # }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_put_response_hop_limit = 1
    http_tokens = "required"
    instance_metadata_tags = "enabled"
  }

}

output "ec2_id" {
    value = {
    for k, v in aws_instance.ec2 : k => v.arn
  }
}
