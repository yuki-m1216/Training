# RDS_Auroa
module "rds_aurora" {
  source = "../../../modules/RDS/Aurora"
  # cluster
  cluster_identifier = "aurora-cluster-example"
  availability_zones = [
    "ap-northeast-1a",
    "ap-northeast-1c",
  ]
  vpc_security_group_ids = [
    module.sg_rds_aurora.sg_id,
  ]
  master_username     = "example"
  storage_encrypted   = true
  skip_final_snapshot = true

  # instance
  count_instance      = 2
  instance_identifier = "aurora-cluster-instance-example"

  # subnet_gourp
  subnet_group_name = "aurora-cluster-subnet-group-example"
  subnet_ids = [
    "subnet-073f1baa14173c1a5",
    "subnet-0c2980ee52f42fc8c",
  ]

  # cluster_parameter_group
  cluster_parameter_group_name        = "aurora-cluster-parameter-group-example"
  cluster_parameter_group_description = "Example ParameterGroup"
  monitoring_role_arn                 = null

  # db_parameter_group
  db_parameter_group_name        = "aurora-db-parameter-group-example"
  db_parameter_group_description = "Example ParameterGroup"
}

# SG
module "sg_rds_aurora" {
  source         = "../../../modules/SecurityGroup"
  sg_name        = "aurora-cluster-example-sg-01"
  sg_description = "aurora-cluster-example-sg-01"
  sg_vpc_id      = "vpc-05b5aeed5c9d8e83e"

  sg_rule = {
    "ingress_01" = {
      type                     = "ingress"
      to_port                  = 3306
      from_port                = 3306
      protocol                 = "tcp"
      source_security_group_id = null
      cidr_blocks              = ["${local.current-ip}/32"]
      description              = "from My IP"
    }
  }
}
