terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 0.13"
  backend "s3" {
    bucket         = "s3-terraform-state-ym"
    region         = "ap-northeast-1"
    key            = "APIGateway.tfstate"
    encrypt        = true
    dynamodb_table = "terrform-state"
  }
}
