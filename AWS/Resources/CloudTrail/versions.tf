terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.68.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
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
