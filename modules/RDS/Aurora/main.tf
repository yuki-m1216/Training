# aurora
resource "aws_rds_cluster" "cluster" {
  cluster_identifier     = var.cluster_identifier
  engine                 = var.engine
  engine_version         = var.engine_version
  port                   = var.port
  availability_zones     = var.availability_zones
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name
  database_name          = var.database_name
  master_username        = var.master_username
  # todo
  master_password                 = "examplepassword"
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  deletion_protection             = var.deletion_protection
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  storage_encrypted               = var.storage_encrypted
  # https://qiita.com/HirokiSakonju/items/18e532fcf1461876c4f3
  kms_key_id                      = var.storage_encrypted == true ? var.kms_key_id == null ? data.aws_kms_key.managed_rds.arn : var.kms_key_id : null
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.parameter_group.name
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.skip_final_snapshot == false ? "${var.cluster_identifier}-final-snapshot" : null
  tags = {
    Name = var.cluster_identifier
  }

  lifecycle {
    ignore_changes = [
      availability_zones,
    ]
  }

}

# instance
resource "aws_rds_cluster_instance" "cluster_instances" {
  count                   = var.count_instance
  identifier              = "${var.instance_identifier}-${count.index}"
  cluster_identifier      = aws_rds_cluster.cluster.id
  instance_class          = var.instance_class
  engine                  = aws_rds_cluster.cluster.engine
  engine_version          = aws_rds_cluster.cluster.engine_version
  db_subnet_group_name    = aws_db_subnet_group.subnet_group.name
  db_parameter_group_name = aws_db_parameter_group.parameter_group.name
  monitoring_interval     = var.monitoring_interval
  monitoring_role_arn     = var.monitoring_interval == 0 ? null : var.monitoring_role_arn

  tags = {
    Name = "${var.instance_identifier}-${count.index}"
  }
}

# subnet_group
resource "aws_db_subnet_group" "subnet_group" {
  name        = var.subnet_group_name
  subnet_ids  = var.subnet_ids
  description = var.subnet_group_description
  tags = {
    Name = var.subnet_group_name
  }
}

# cluster_parameter_group
resource "aws_rds_cluster_parameter_group" "parameter_group" {
  name        = var.cluster_parameter_group_name
  family      = var.parameter_group_family
  description = var.cluster_parameter_group_description

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = {
    Name = var.cluster_parameter_group_name
  }
}

# db_parameter_group
resource "aws_db_parameter_group" "parameter_group" {
  name        = var.db_parameter_group_name
  family      = var.parameter_group_family
  description = var.db_parameter_group_description

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = {
    Name = var.db_parameter_group_name
  }
}

# AWS managed keys RDS
data "aws_kms_key" "managed_rds" {
  key_id = "alias/aws/rds"
}
