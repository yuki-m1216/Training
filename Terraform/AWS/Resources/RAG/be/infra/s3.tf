### embed-doc ###
/*
s3_filesに配置したベクトルストアで使用するファイルを格納するs3バケットを作成します。
*/
resource "aws_s3_bucket" "embeddings" {
  bucket = "bedrock-embeddings-files-bucket"
  tags = {
    Name = "bedrock-embeddings-files-bucket"
  }

  force_destroy = true
}

resource "aws_s3_object" "embeddings" {
  bucket = aws_s3_bucket.embeddings.id
  key    = "files/bedrock-ug.pdf"
  source = "${path.module}/files/bedrock-ug.pdf"
  # etag = filemd5("${path.module}/files/bedrock-ug.pdf")
  # zipサイズが16MBを超えるため、etagが変わるため、source_hashを使用する
  source_hash = filemd5("${path.module}/files/bedrock-ug.pdf")
}

resource "aws_s3_bucket" "embed_doc_layer" {
  bucket = "embed-doc-lambda-layer-bucket"
  tags = {
    Name = "embed-doc-lambda-layer-bucket"
  }
}

resource "aws_s3_object" "embed_doc_layer" {
  bucket = aws_s3_bucket.embed_doc_layer.id
  key    = "layer.zip"
  source = data.archive_file.embed_doc_layer.output_path
  # etag = filemd5(data.archive_file.layer.output_path)ではすでに存在しているファイルのmd5を取得してしまうためエラーになる 
  # data.archive_file.layer.output_md5を使用することで解決し、depends_onを使用しなくても正常に動作する
  # https://stackoverflow.com/questions/68882914/terraform-aws-s3-bucket-object-not-triggered-by-archive-file
  # etag = data.archive_file.layer.output_md5 
  # zipサイズが16MBを超えるため、etagが変わるため、source_hashを使用する
  source_hash = data.archive_file.embed_doc_layer.output_md5
}

### vector-database ###
resource "aws_s3_bucket" "vector_database" {
  bucket = "vector-ingest-lambda-layer-bucket"
  tags = {
    Name = "vector-ingest-lambda-layer-bucket"
  }
}

resource "aws_s3_object" "vector_database" {
  bucket = aws_s3_bucket.vector_database.id
  key    = "layer.zip"
  source = data.archive_file.vector_database_layer.output_path
  # etag = filemd5(data.archive_file.layer.output_path)ではすでに存在しているファイルのmd5を取得してしまうためエラーになる 
  # data.archive_file.layer.output_md5を使用することで解決し、depends_onを使用しなくても正常に動作する
  # https://stackoverflow.com/questions/68882914/terraform-aws-s3-bucket-object-not-triggered-by-archive-file
  # etag = data.archive_file.layer.output_md5 
  # zipサイズが16MBを超えるため、etagが変わるため、source_hashを使用する
  source_hash = data.archive_file.vector_database_layer.output_md5
}

### answer-user-query ###
resource "aws_s3_bucket" "answer_user_query" {
  bucket = "answer-user-query-lambda-layer-bucket"
  tags = {
    Name = "answer-user-query-lambda-layer-bucket"
  }
}

resource "aws_s3_object" "answer_user_query" {
  bucket = aws_s3_bucket.answer_user_query.id
  key    = "layer.zip"
  source = data.archive_file.answer_user_query_layer.output_path
  # etag = filemd5(data.archive_file.layer.output_path)ではすでに存在しているファイルのmd5を取得してしまうためエラーになる 
  # data.archive_file.layer.output_md5を使用することで解決し、depends_onを使用しなくても正常に動作する
  # https://stackoverflow.com/questions/68882914/terraform-aws-s3-bucket-object-not-triggered-by-archive-file
  # etag = data.archive_file.layer.output_md5 
  # zipサイズが16MBを超えるため、etagが変わるため、source_hashを使用する
  source_hash = data.archive_file.answer_user_query_layer.output_md5
}