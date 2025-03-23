data "aws_caller_identity" "current" {}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../src/embedding/main.py"
  output_path = "${path.module}/../dist/embedding/main.zip"
}

data "archive_file" "layer" {
  type        = "zip"
  source_dir  = "${path.module}/../src/embedding/layer"
  output_path = "${path.module}/../dist/embedding/layer.zip"
}