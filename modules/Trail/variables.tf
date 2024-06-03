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
variable "bucket_force_destroy" {
  type        = bool
  description = "A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error."
  default     = false
}
