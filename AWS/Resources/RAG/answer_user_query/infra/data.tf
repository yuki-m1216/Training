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

# vector-database.tfstateから取得した値を使用する
data "terraform_remote_state" "vector_database" {
  backend = "s3"
  config = {
    bucket = "s3-terraform-state-y-mitsuyama"
    key    = "vector-database.tfstate"
    region = "ap-northeast-1"
  }
}