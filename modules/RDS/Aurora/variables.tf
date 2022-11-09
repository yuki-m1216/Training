# aurora
variable "cluster_identifier" {
  type        = string
  description = "The cluster identifier."
}

variable "engine" {
  type        = string
  description = "The name of the database engine to be used for this DB cluster."
  default     = "aurora-mysql"
}

variable "engine_version" {
  type        = string
  description = "The database engine version."
  default     = "5.7.mysql_aurora.2.10.2"
}

variable "port" {
  type        = number
  description = "The port on which the DB accepts connections."
  default     = 3306
}

variable "availability_zones" {
  type           = list(string)
  desdescription = " List of EC2 Availability Zones for the DB cluster storage where DB cluster instances can be created."
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "List of VPC security groups to associate with the Cluster."
}

variable "database_name" {
  type        = string
  description = "Name for an automatically created database on cluster creation."
  default     = "mydb"
}

variable "master_username" {
  type        = string
  description = "Username for the master DB user."
}

variable "backup_retention_period" {
  type        = number
  description = "The days to retain backups for."
  default     = 1
}

variable "preferred_backup_window" {
  type        = string
  description = "The daily time range during which automated backups are created."
  default     = "15:00-17:00"
}

variable "preferred_maintenance_window" {
  type        = string
  description = "The weekly time range during which system maintenance can occur."
  default     = "sat:15:00-sat:17:0"
}

variable "deletion_protection" {
  type        = bool
  description = "If the DB instance should have deletion protection enabled."
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  description = "Set of log types to export to cloudwatch."
  default = [
    "audit",
    "error",
    "general",
    "slowquery",
  ]
}

variable "kms_key_id" {
  type        = string
  description = "The ARN for the KMS encryption key."
  default     = null
}
variable "skip_final_snapshot" {
  type        = bool
  description = "Determines whether a final DB snapshot is created before the DB cluster is deleted."
  default     = false
}

# instance
variable "count_instance" {
  type                   = number
  descriptiondescription = "count for instance"
}

variable "instance_identifier" {
  type        = string
  description = "The identifier for the RDS instance"
}

variable "instance_class" {
  type        = string
  description = " The instance class to use"
  default     = "db.t3.small"
}

variable "monitoring_role_arn" {
  type        = string
  description = "The ARN for the IAM role for enhanced monitoring"
}

variable "monitoring_interval" {
  type        = number
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance."
  default     = 0
}

# subnet_group
variable "subnet_group_name" {
  type        = string
  description = "The name of the DB subnet group."
}

variable "subnet_ids" {
  type           = list(string)
  desdescription = "A list of VPC subnet IDs."
}

variable "subnet_group_description" {
  type        = string
  description = " The description of the DB subnet group."
  default     = "Managed by Terraform."
}

# cluster_parameter_group
variable "cluster_parameter_group_name" {
  type        = string
  description = "The name of the DB cluster parameter group."
}

variable "parameter_group_family" {
  type        = string
  description = " The family of the DB and cluster parameter group."
  default     = "aurora-mysql5.7"
}

variable "cluster_parameter_group_description" {
  type        = string
  description = "The description of the DB cluster parameter group."
}

variable "cluster_parameters" {
  type        = map(any)
  description = "map of cluster parameters"
  default     = null
}

# db_parameter_group
variable "db_parameter_group_name" {
  type        = string
  description = "The name of the DB parameter group."
}

variable "db_parameter_group_description" {
  type        = string
  description = "The description of the DB parameter group."
  default     = "Managed by Terraform."
}

variable "db_parameters" {
  type        = map(any)
  description = "map of DB parameters"
  default     = null
}
