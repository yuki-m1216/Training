terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [aws.alternate]
      version = ">= 5.68.0"
    }
  }
}