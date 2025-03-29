#--------------------------------------------------
# Provider
#--------------------------------------------------

# default
provider "aws" {
  region = "ap-northeast-1"
}
provider "opensearch" {
  url = module.OpenSearchServerless.collection.collection_endpoint
  aws_region = "ap-northeast-1"
  healthcheck = false
}