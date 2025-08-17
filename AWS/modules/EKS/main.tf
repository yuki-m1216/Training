module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name_prefix    = var.key_name_prefix
  create_private_key = var.create_private_key
}

# SSH接続用セキュリティグループ（EKSノード用）
resource "aws_security_group" "remote_access" {
  name_prefix = "${var.cluster_name}-remote-access"
  description = "Allow SSH access to EKS instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-remote-access"
    }
  )
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  cluster_ip_family              = var.cluster_ip_family
  vpc_id                         = var.vpc_id
  subnet_ids                     = var.subnet_ids
  control_plane_subnet_ids       = var.control_plane_subnet_ids
  create_kms_key                 = var.create_kms_key
  cluster_encryption_config      = var.cluster_encryption_config
  enable_irsa                    = var.enable_irsa

  cluster_addons = var.cluster_addons

  eks_managed_node_group_defaults = {
    ami_type       = var.node_ami_type
    instance_types = var.node_instance_types
    subnet_ids     = var.node_subnet_ids
  }

  eks_managed_node_groups = {
    default_node_group = {
      use_custom_launch_template = false
      disk_size                  = var.node_disk_size
      remote_access = {
        ec2_ssh_key               = module.key_pair.key_pair_name
        source_security_group_ids = [aws_security_group.remote_access.id]
      }
    }
  }

  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  tags = var.tags
}