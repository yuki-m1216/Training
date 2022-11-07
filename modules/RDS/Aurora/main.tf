# aurora
resource "aws_rds_cluster" "cluster" {
  cluster_identifier     = var.cluster_identifier
  engine                 = var.engine
  engine_version         = var.engine_version
  port                   = var.port
  availability_zones     = var.availability_zones
  vpc_security_group_ids = var.vpc_security_group_ids
  database_name          = var.database_name
  master_username        = var.master_username
  # todo
  master_password                 = "bar"
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  deletion_protection             = var.deletion_protection
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  kms_key_id                      = var.kms_key_id
  storage_encrypted               = var.storage_encrypted
  tags {
    Name = var.name
  }
}

# instance
resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = var.count
  identifier         = "${var.instance_identifier}-${count.index}"
  cluster_identifier = aws_rds_cluster.cluster.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.cluster.engine
  engine_version     = aws_rds_cluster.cluster.engine_version
}

# parameter_group
resource "aws_rds_cluster_parameter_group" "default" {
  name        = "rds-cluster-pg"
  family      = "aurora5.6"
  description = "RDS default cluster parameter group"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}

# role_association
resource "aws_rds_cluster_role_association" "example" {
  db_cluster_identifier = aws_rds_cluster.example.id
  feature_name          = "S3_INTEGRATION"
  role_arn              = aws_iam_role.example.arn
}


# output
output "aws_launch_template_id" {
  value = aws_launch_template.launch_template.id
}
