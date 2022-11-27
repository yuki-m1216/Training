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
  default     = null
}
