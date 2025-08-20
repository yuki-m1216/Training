#--------------------------------------------------
# Provider
#--------------------------------------------------
# mac
# export NEW_RELIC_ACCOUNT_ID="<your New Relic Account ID>"
# export NEW_RELIC_API_KEY="<your New Relic User API key>"
# windows
# $Env:NEW_RELIC_ACCOUNT_ID="<your New Relic Account ID>"
# $Env:NEW_RELIC_API_KEY="<your New Relic User API key>"
provider "newrelic" {
  region = "US" # US or EU (defaults to US)
}

provider "aws" {
  region = "ap-northeast-1"
}
