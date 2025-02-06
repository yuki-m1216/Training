module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name_prefix    = "eks"
  create_private_key = true
}

resource "aws_security_group" "remote_access" {
  name_prefix = "eks-remote-access"
  description = "allow ssh access to eks instances"
  vpc_id      = data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-remote-access"
  }
}
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name                   = "eks-cluster"
  cluster_version                = "1.31"
  cluster_endpoint_public_access = true
  cluster_ip_family              = "ipv4"
  vpc_id                         = data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id
  subnet_ids = [
    values(data.terraform_remote_state.mainvpc.outputs.mainvpc.public_subnet_id)[0],
    values(data.terraform_remote_state.mainvpc.outputs.mainvpc.public_subnet_id)[1],
    values(data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id)[0],
    values(data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id)[1]
  ]
  control_plane_subnet_ids = [
    values(data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id)[0],
    values(data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id)[1]
  ]
  create_kms_key            = false
  cluster_encryption_config = {}
  enable_irsa               = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    esk-pod-identity-agent = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          AWS_VPC_K8S_CNI_EXTERNALSNAT = "true"
          ENABLE_PREFIX_DELEGATION     = "true"
          WARM_PREFIX_TARGET           = "1"
        }
      })
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3a.medium"]
    subnet_ids = [
      values(data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id)[0],
      values(data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id)[1]

    ]
  }

  eks_managed_node_groups = {
    default_node_group = {
      use_custom_launch_template = false
      disk_size                  = 20
      remote_access = {
        ec2_ssh_key               = module.key_pair.key_pair_name
        source_security_group_ids = [aws_security_group.remote_access.id]
      }
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = {
    "Name" = "eks-cluster"
  }
}
