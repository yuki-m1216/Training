/*
s3_filesに配置したベクトルストアで使用するファイルを格納するs3バケットを作成します。
*/
resource "aws_s3_bucket" "embeddings" {
  bucket = "bedrock-embeddings-files-bucket"
  tags = {
    Name        = "bedrock-embeddings-files-bucket"
  }
}

resource "aws_s3_object" "embeddings" {
  bucket = aws_s3_bucket.embeddings.id
  key = "files/bedrock-ug.pdf"
  source = "${path.module}/files/bedrock-ug.pdf"
  etag = filemd5("${path.module}/files/bedrock-ug.pdf")
}

resource "aws_s3_bucket" "embed_doc_layer" {
  bucket = "embed-doc-lambda-layer-bucket"
  tags = {
    Name        = "embed-doc-lambda-layer-bucket"
  }
}

resource "aws_s3_object" "embed_doc_layer" {
  bucket = aws_s3_bucket.embed_doc_layer.id
  key = "layer.zip"
  source = "${path.module}/../dist/layer.zip"
  etag = filemd5("${path.module}/../dist/layer.zip")

  depends_on = [data.archive_file.layer]
}