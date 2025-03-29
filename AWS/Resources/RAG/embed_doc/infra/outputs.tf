output "bedrock_embeddings_files_bucket_bucket" {
  value = aws_s3_bucket.embeddings.bucket
}

output "bedrock_embeddings_files_bucket_arn" {
  value = aws_s3_bucket.embeddings.arn
}