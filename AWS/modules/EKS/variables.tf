variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_ip_family" {
  description = "The IP family used by the cluster"
  type        = string
  default     = "ipv4"
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster and its nodes will be provisioned"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster will be deployed"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster control plane will be deployed"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "A list of subnet IDs where the EKS managed node groups will be deployed"
  type        = list(string)
}

variable "create_kms_key" {
  description = "Controls if a KMS key for envelope encryption should be created"
  type        = bool
  default     = false
}

variable "cluster_encryption_config" {
  description = "Configuration block with encryption configuration for the cluster"
  type        = any
  default     = {}
}

variable "enable_irsa" {
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type        = any
  default = null
}

variable "eks_managed_node_group_defaults" {
  description = "Map of EKS managed node group default configurations"
  type        = any
  default     = {}
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group configurations"
  type        = any
  default     = {}
}

variable "node_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  type        = string
  default     = "AL2_x86_64"
}

variable "node_instance_types" {
  description = "List of instance types associated with the EKS Node Group"
  type        = list(string)
  default     = ["t3a.medium"]
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator as an administrator"
  type        = bool
  default     = true
}

variable "key_name_prefix" {
  description = "Prefix for the key pair name"
  type        = string
  default     = "eks"
}

variable "create_private_key" {
  description = "Whether to create a private key"
  type        = bool
  default     = true
}

variable "ssh_allowed_cidr_blocks" {
  description = "List of CIDR blocks that can access the instances via SSH"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}