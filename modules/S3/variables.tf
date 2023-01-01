# bucket
variable "bucket_name" {
  type        = string
  description = "The name of the bucket."
}

variable "bucket_force_destroy" {
  type        = bool
  description = "A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error."
  default     = false
}

variable "object_lock_enabled" {
  type        = bool
  description = "Indicates whether this bucket has an Object Lock configuration enabled."
  default     = false
}

variable "object_ownership" {
  type        = string
  description = "Configuration block(s) with Ownership Controls rules."
  default     = "BucketOwnerEnforced"
}

# server_side_encryption_configuration
variable "sse_algorithm" {
  type        = string
  description = "The server-side encryption algorithm to use. Valid values are AES256 and aws:kms"
  default     = "AES256"
}

variable "kms_master_key_id" {
  type        = string
  description = "The AWS KMS master key ID used for the SSE-KMS encryption."
  default     = null
}

# versioning
variable "versioning_status" {
  type        = string
  description = "The versioning state of the bucket. Valid values: Enabled, Suspended, or Disabled."
  default     = "Disabled"
}

# lifecycle_configuration
variable "lifecycle_configuration" {
  type        = bool
  description = "whether to use lifecycle"
  default     = false
}

variable "lifecycle_rules" {
  type = list(object({
    id     = string
    status = string
    prefix = string

    expiration = list(object({
      days                         = number
      date                         = string
      expired_object_delete_marker = bool
    }))

    transition = list(object({
      days          = number
      date          = string
      storage_class = string
    }))

    noncurrent_version_expiration = list(object({
      noncurrent_days           = number
      newer_noncurrent_versions = number
    }))

    noncurrent_version_transition = list(object({
      noncurrent_days           = number
      newer_noncurrent_versions = number
      storage_class             = string
    }))

  }))
  description = "List of configuration blocks describing the rules managing the replication."
  default     = []
}

# s3_bucket_public_access_block
variable "block_public_acls" {
  type        = bool
  description = "Whether Amazon S3 should block public ACLs for this bucket."
  default     = true
}

variable "ignore_public_acls" {
  type        = bool
  description = "Whether Amazon S3 should ignore public ACLs for this bucket."
  default     = true
}

variable "block_public_policy" {
  type        = bool
  description = "Whether Amazon S3 should block public bucket policies for this bucket."
  default     = true
}

variable "restrict_public_buckets" {
  type        = bool
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket."
  default     = true
}

# s3_bucket_policy
variable "create_bucket_policy" {
  type        = bool
  description = "whether to create bucketpolicy"
  default     = false
}

variable "bucket_policy_document" {
  type        = string
  description = "The text of the policy"
}
