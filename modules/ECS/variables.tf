# ecs_cluster
variable "cluster_name" {
  type        = string
  description = "Name of the cluster (up to 255 letters, numbers, hyphens, and underscores)"
}

variable "containerInsights" {
  type    = bool
  default = false
}
