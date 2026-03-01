terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.19.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
  }

  backend "s3" {
    bucket       = "s3-terraform-state-y-mitsuyama"
    region       = "ap-northeast-1"
    key          = "ConsoleLoginAlarmLambda.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
