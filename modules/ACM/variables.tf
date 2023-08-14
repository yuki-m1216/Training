# aws_acm_certificate
variable "domain_name" {
  type        = string
  description = "Fully qualified domain name (FQDN) in the certificate."
}

variable "subject_alternative_names" {
  type        = list(string)
  description = " Set of domains that should be SANs in the issued certificate."
  default     = []
}

variable "validation_method" {
  type        = string
  description = "Which method to use for validation. DNS or EMAIL are valid."
  default     = "DNS"
}

# data aws_route53_zone
variable "private_zone" {
  type        = bool
  description = "Used with name field to get a private Hosted Zone."
  default     = false
}
