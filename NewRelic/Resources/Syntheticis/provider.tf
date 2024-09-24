#--------------------------------------------------
# Provider
#--------------------------------------------------
# export NEW_RELIC_ACCOUNT_ID="<your New Relic Account ID>"
# export NEW_RELIC_API_KEY="<your New Relic User API key>"
provider "newrelic" {
  region = "US"        # US or EU (defaults to US)
}
