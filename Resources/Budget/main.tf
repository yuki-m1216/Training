provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  required_version = ">= 0.13.0"
  backend "s3" {
    bucket  = "s3-terraform-state-y-mitsuyama"
    region  = "ap-northeast-1"
    key     = "Budget.tfstate"
    encrypt = true
  }
}

module "SNS" {
  source                    = "../../modules/Budget"
  dudget_name               = "Budget Usage"
  budget_type               = "COST"
  limit_amount              = "82"
  time_unit                 = "MONTHLY"
  threshold                 = "100"
  subscriber_sns_topic_arns = ["arn:aws:sns:ap-northeast-1:${data.aws_caller_identity.current.account_id}:Budget_SNS_topic"]
}
