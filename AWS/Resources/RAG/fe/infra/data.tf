data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "terraform_remote_state" "mainvpc" {
  backend = "s3"

  config = {
    bucket = "s3-terraform-state-y-mitsuyama"
    key    = "MainVPC.tfstate"
    region = "ap-northeast-1"
  }
}

# data "terraform_remote_state" "answer_user_query" {
#   backend = "s3"

#   config = {
#     bucket = "s3-terraform-state-y-mitsuyama"
#     key    = "answer-user-query.tfstate"
#     region = "ap-northeast-1"
#   }
# }