### Cognito ###
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

# user_pool_client
variable "user_pool_client_name" {
  type        = string
  description = "Name of the application client."
}

# identity_pool
variable "identity_pool_name" {
  type        = string
  description = "The Cognito Identity Pool name."
}

### IAM ###
## authenticated
# iam_role
variable "authenticated_iam_role_name" {
  type        = string
  description = "Friendly name of the role."
}

variable "authenticated_iam_role_description" {
  type        = string
  description = "Description of the role."
}

# iam_policy
variable "authenticated_iam_policy_name" {
  type        = string
  description = "The name of the policy."
}

variable "authenticated_iam_policy_description" {
  type        = string
  description = "Description of the IAM policy."
}

## unauthenticated
# iam_role
variable "unauthenticated_iam_role_name" {
  type        = string
  description = "Friendly name of the role."
}

variable "unauthenticated_iam_role_description" {
  type        = string
  description = "Description of the role."
}

# iam_policy
variable "unauthenticated_iam_policy_name" {
  type        = string
  description = "The name of the policy."
}

variable "unauthenticated_iam_policy_description" {
  type        = string
  description = "Description of the IAM policy."
}
