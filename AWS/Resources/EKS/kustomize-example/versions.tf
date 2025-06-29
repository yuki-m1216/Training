terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket = "s3-terraform-state-y-mitsuyama"
    key    = "EKS/kustomize-example/terraform.tfstate"
    region = "ap-northeast-1"
  }
}