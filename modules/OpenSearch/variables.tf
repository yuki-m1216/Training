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
