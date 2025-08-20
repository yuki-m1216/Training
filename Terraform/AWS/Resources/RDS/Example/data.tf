data "http" "checkip" {
  url = "http://ipv4.icanhazip.com/"
}

# data resource kms ssm
data "aws_kms_key" "alias_ssm" {
  key_id = "alias/aws/ssm"
}
