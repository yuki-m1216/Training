# bucket
resource "aws_s3_bucket" "bucket" {
  bucket              = var.bucket_name
  force_destroy       = var.bucket_force_destroy
  object_lock_enabled = var.object_lock_enabled

  tags = {
    Name = var.bucket_name
  }
}

# ownership_controls
/*
https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-best-practices.html
Bucket owner enforced (recommended) – ACLs are disabled, and the bucket owner automatically owns and has full control over every object in the bucket. 
ACLs no longer affect permissions to data in the S3 bucket. The bucket uses policies exclusively to define access control.
*/
resource "aws_s3_bucket_ownership_controls" "ownership_controls" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# server_side_encryption_configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.sse_algorithm == "AES256" ? null : var.kms_master_key_id
    }
  }
}

# versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.versioning_status
  }
}

# lifecycle_configuration
/*
https://github.com/terraform-aws-modules/terraform-aws-s3-bucket/blob/v0.0.1/main.tf#L54
https://github.com/terraform-aws-modules/terraform-aws-s3-bucket/blob/v0.0.1/examples/s3-lifecycle-rule/main.tf#L17
*/
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  count = var.lifecycle_configuration ? 1 : 0
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.versioning]

  bucket = aws_s3_bucket.bucket.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      filter {
        prefix = rule.value.prefix
      }

      dynamic "expiration" {
        for_each = rule.value.expiration == null ? [] : rule.value.expiration

        content {
          days                         = expiration.value.days
          date                         = expiration.value.date
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition == null ? [] : rule.value.transition

        content {
          days          = transition.value.days
          date          = transition.value.date
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration == null ? [] : rule.value.noncurrent_version_expiration

        content {
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition == null ? [] : rule.value.noncurrent_version_transition

        content {
          noncurrent_days           = noncurrent_version_transition.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_transition.value.newer_noncurrent_versions
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }

    }
  }
}
