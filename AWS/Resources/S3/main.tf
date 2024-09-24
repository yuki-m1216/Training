# s3
module "s3_bucket" {
  source = "../../modules/S3"

  # bucket
  bucket_name = "test-ymitsuyama-s3bucket"

  # versionings
  versioning_status = "Enabled"

  # lifecycle_configuration
  lifecycle_configuration = true
  lifecycle_rules = [{
    id     = "test-id"
    status = "Enabled"
    prefix = ""

    expiration = [{
      days                         = 30
      date                         = null
      expired_object_delete_marker = null
    }]

    transition = []

    noncurrent_version_expiration = [{
      noncurrent_days           = 30
      newer_noncurrent_versions = 1
    }]

    noncurrent_version_transition = []
  }]

}
