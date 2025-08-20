data "aws_caller_identity" "current" {}

### embed-doc ###
data "archive_file" "embed_doc_lambda" {
  type        = "zip"
  source_file = "${path.module}/../src/embed_doc/main.py"
  output_path = "${path.module}/../dist/embed_doc/main.zip"
}

data "archive_file" "embed_doc_layer" {
  type        = "zip"
  source_dir  = "${path.module}/../src/embed_doc/layer"
  output_path = "${path.module}/../dist/embed_doc/layer.zip"
}

### vector_database ###
data "archive_file" "vector_database_lambda" {
  type        = "zip"
  source_file = "${path.module}/../src/vector_database/main.py"
  output_path = "${path.module}/../dist/vector_database/main.zip"
}

data "archive_file" "vector_database_layer" {
  type        = "zip"
  source_dir  = "${path.module}/../src/vector_database/layer"
  output_path = "${path.module}/../dist/vector_database/layer.zip"
}

### answer_user_query ###
data "archive_file" "answer_user_query_lambda" {
  type        = "zip"
  source_file = "${path.module}/../src/answer_user_query/main.py"
  output_path = "${path.module}/../dist/answer_user_query/main.zip"
}

data "archive_file" "answer_user_query_layer" {
  type        = "zip"
  source_dir  = "${path.module}/../src/answer_user_query/layer"
  output_path = "${path.module}/../dist/answer_user_query/layer.zip"
}

data "aws_iam_policy_document" "aws_api_gateway_resource_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_rest_api.rag_be_api.execution_arn}/*"]

    condition {
      test     = "StringEqualsIfExists"
      variable = "aws:SourceVpc"
      values = [
        data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id
      ]
    }
  }
}

# 既存のvpc情報を取得
data "terraform_remote_state" "mainvpc" {
  backend = "s3"

  config = {
    bucket = "s3-terraform-state-y-mitsuyama"
    key    = "MainVPC.tfstate"
    region = "ap-northeast-1"
  }
}