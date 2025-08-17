module "eks_cluster" {
  source = "../../../modules/EKS"

  cluster_name    = "kustomize-example-cluster"
  cluster_version = "1.32"
  vpc_id          = data.terraform_remote_state.mainvpc.outputs.mainvpc.mainvpc_id

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

  node_subnet_ids = [
    values(data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id)[0],
    values(data.terraform_remote_state.mainvpc.outputs.mainvpc.private_subnet_id)[1]
  ]

  node_instance_types = ["t3a.medium"]
  node_disk_size      = 20

  tags = {
    Name        = "kustomize-example-cluster"
    Environment = "example"
    Purpose     = "kustomize-demo"
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    eks-pod-identity-agent = {
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
}