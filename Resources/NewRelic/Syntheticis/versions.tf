terraform {
  required_providers {
    newrelic = {
      source = "newrelic/newrelic"
    }
  }
  required_version = ">= 0.13"
  backend "s3" {
    bucket         = "s3-terraform-state-y-mitsuyama"
    region         = "ap-northeast-1"
    key            = "newrelic-synthetics.tfstate"
    encrypt        = true
    dynamodb_table = "terrform-state"
  }
}
