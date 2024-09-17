terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    template = {
      source = "hashicorp/template"
    }
  }

  backend "s3" {
    bucket         = "s3-terraform-state-y-mitsuyama"
    region         = "ap-northeast-1"
    key            = "CloudTrail.tfstate"
    encrypt        = true
    dynamodb_table = "terrform-state"
  }
}
