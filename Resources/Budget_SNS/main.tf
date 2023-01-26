provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  required_version = ">= 0.13.0"
  backend "s3" {
    bucket  = "s3-terraform-state-y-mitsuyama"
    region  = "ap-northeast-1"
    key     = "SNS.tfstate"
    encrypt = true
  }
}

data "aws_caller_identity" "current" {}

data "template_file" "policy" {
  template = file("./Policy.json.tpl")

  vars = {
    account_id = data.aws_caller_identity.current.account_id
  }
}

module "SNS" {
  source = "../../modules/SNS"
  # SNS_topic
  topic_name   = "Budget_SNS_topic"
  display_name = "Budget_SNS_topic"

  # SNS_topic_policy
  policy = data.template_file.policy.rendered

  #SNS_subscription_email
  endpoint = var.endpoint
}


