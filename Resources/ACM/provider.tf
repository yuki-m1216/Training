#--------------------------------------------------
# Provider
#--------------------------------------------------

# default
provider "aws" {
  region = "ap-northeast-1"
}

# aws ec2 describe-regions --output text --query 'Regions[].{Name:RegionName}'
# multi region
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}
