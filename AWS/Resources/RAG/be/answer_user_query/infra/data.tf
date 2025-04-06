data "aws_caller_identity" "current" {}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../src/main.py"
  output_path = "${path.module}/../dist/main.zip"
}

data "archive_file" "layer" {
  type        = "zip"
  source_dir  = "${path.module}/../src/layer"
  output_path = "${path.module}/../dist/layer.zip"
}

data "aws_iam_policy_document" "aws_api_gateway_resource_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_rest_api.this.execution_arn}/*"]

    condition {
      test     = "StringEqualsIfExists"
      variable = "aws:SourceVpc"
      values = [
        data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id
      ]
    }
  }
}

# vector-database.tfstateから取得した値を使用する
data "terraform_remote_state" "vector_database" {
  backend = "s3"
  config = {
    bucket = "s3-terraform-state-y-mitsuyama"
    key    = "vector-database.tfstate"
    region = "ap-northeast-1"
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