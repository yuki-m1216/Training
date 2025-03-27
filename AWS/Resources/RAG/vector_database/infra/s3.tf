resource "aws_s3_bucket" "this" {
  bucket = "vector-ingest-lambda-layer-bucket"
  tags = {
    Name = "vector-ingest-lambda-layer-bucket"
  }
}

resource "aws_s3_object" "this" {
  bucket = aws_s3_bucket.this.id
  key    = "layer.zip"
  source = data.archive_file.layer.output_path
  # etag = filemd5(data.archive_file.layer.output_path)ではすでに存在しているファイルのmd5を取得してしまうためエラーになる 
  # data.archive_file.layer.output_md5を使用することで解決し、depends_onを使用しなくても正常に動作する
  # https://stackoverflow.com/questions/68882914/terraform-aws-s3-bucket-object-not-triggered-by-archive-file
  # etag = data.archive_file.layer.output_md5 
  # zipサイズが16MBを超えるため、etagが変わるため、source_hashを使用する
  source_hash = data.archive_file.layer.output_md5
}