# user_pool
variable "user_pool_name" {
  type        = string
  description = "Name of the user pool."
}

# user_pool_domain
variable "user_pool_domain" {
  type        = string
  description = " For custom domains, this is the fully-qualified domain name, such as auth.example.com."
}

# identity_pool
variable "identity_pool_name" {
  type        = string
  description = "The Cognito Identity Pool name."
}
