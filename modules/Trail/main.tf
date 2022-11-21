# variable 
# cloudtrail
variable "cloudtrailname" {}
variable "is_multi_region_trail" {}
variable "include_global_service_events" {}
variable "read_write_type" {}
variable "include_management_events" {}

# S3
variable "bucketname" {}
variable "policy" {}
variable "id" {}
variable "expiration_days" {}
variable "status" {}

# Trail
resource "aws_cloudtrail" "cloudtrail" {
  name                          = var.cloudtrailname
  s3_bucket_name                = aws_s3_bucket.cloudtrailbucket.id
  is_multi_region_trail         = var.is_multi_region_trail
  include_global_service_events = var.include_global_service_events

  event_selector {
    read_write_type           = var.read_write_type
    include_management_events = var.include_management_events
  }
}

# S3
resource "aws_s3_bucket" "cloudtrailbucket" {
  bucket = var.bucketname
}

# S3 policy
resource "aws_s3_bucket_policy" "cloudtrailbucket_policy" {
  bucket = aws_s3_bucket.cloudtrailbucket.id
  policy = var.policy
}

# S3 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrailbucket_encryption" {
  bucket = aws_s3_bucket.cloudtrailbucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 lifecycle_configuration
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrailbucket_lifecycle" {
  bucket = aws_s3_bucket.cloudtrailbucket.id

  rule {
    id = var.id
    expiration {
      days = var.expiration_days
    }
    # noncurrent_version_expiration {
    #   days = 
    # }
    # noncurrent_version_transition {
    #   days =
    # }
    # transition {
    #   days          = 30
    #   storage_class = "STANDARD_IA"
    # }
    status = var.status
  }
}