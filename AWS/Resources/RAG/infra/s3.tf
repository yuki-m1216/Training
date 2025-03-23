/*
s3_filesに配置したベクトルストアで使用するファイルを格納するs3バケットを作成します。
*/
resource "aws_s3_bucket" "embeddings" {
  bucket = "bedrock-embeddings-s3-files-bucket"
  tags = {
    Name        = "bedrock-embeddings-s3-files-bucket"
  }
}

resource "aws_s3_object" "embeddings" {
  bucket = aws_s3_bucket.embeddings.id
  key = "files/bedrock-ug.pdf"
  source = "${path.module}/s3_files/bedrock-ug.pdf"
  etag = filemd5("${path.module}/s3_files/bedrock-ug.pdf")
}

resource "aws_s3_bucket" "embeddings_layer" {
  bucket = "bedrock-embeddings-s3-layer-bucket"
  tags = {
    Name        = "bedrock-embeddings-s3-layer-bucket"
  }
}

resource "aws_s3_object" "embeddings_layer" {
  bucket = aws_s3_bucket.embeddings_layer.id
  key = "layer.zip"
  source = "${path.module}/../dist/embedding/layer.zip"
  etag = filemd5("${path.module}/../dist/embedding/layer.zip")

  depends_on = [data.archive_file.layer]
}