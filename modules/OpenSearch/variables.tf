# opensearch
variable "domain_name" {
  type        = string
  description = "Name of the domain."
}

variable "engine_version" {
  type        = string
  description = "Either Elasticsearch_X.Y or OpenSearch_X.Y to specify the engine version for the Amazon OpenSearch Service domain."
}

variable "instance_type" {
  type        = string
  description = "Instance type of data nodes in the cluster."
  default     = "t3.small.search"
}

variable "ebs_enabled" {
  type        = bool
  description = "Whether EBS volumes are attached to data nodes in the domain."
  default     = false
}

variable "volume_size" {
  type        = number
  description = "Size of EBS volumes attached to data nodes (in GiB)."
  default     = 10
}

variable "advanced_security_options" {
  type = list(object({
    enabled                        = bool
    internal_user_database_enabled = bool
    master_user_name               = string
    master_user_password           = string
    master_user_arn                = string
  }))
  description = "Configuration block for fine-grained access control."
  default     = null
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ARN to encrypt the Elasticsearch domain with."
}

# domain policy
variable "create_domain_policy" {
  type        = bool
  description = "Whether to create a domain policy"
  default     = false
}

variable "access_policies" {
  type        = string
  description = "IAM policy document specifying the access policies for the domain."
  default     = ""
}
