# launch_template
variable "cluster_identifier" {
  type        = string
  description = "The cluster identifier."
}

variable "engine" {
  type        = string
  description = "The name of the database engine to be used for this DB cluster."
  default     = "aurora-mysql"
}
