data "aws_caller_identity" "current" {}

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