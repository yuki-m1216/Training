/*
s3_filesに配置したベクトルストアで使用するファイルを格納するs3バケットを作成します。
*/
resource "aws_s3_bucket" "this" {
  bucket = "bedrock-embeddings-s3-files-bucket"
  tags = {
    Name        = "bedrock-embeddings-s3-files-bucket"
  }
}

resource "aws_s3_object" "this" {
  bucket = aws_s3_bucket.this.id
  key = "files"
  source = "${path.module}/s3_files/bedrock-ug.pdf"
  etag = filemd5("${path.module}/s3_files/bedrock-ug.pdf")
}