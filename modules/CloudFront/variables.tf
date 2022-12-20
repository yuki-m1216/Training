# cloudfront
variable "origin" {
  type = list(object({
    domain_name              = string
    origin_access_control_id = string
    origin_id                = string
    origin_path              = string

    custom_origin_config = list(object({
      http_port                = number
      https_port               = number
      origin_protocol_policy   = string
      origin_ssl_protocols     = list(string)
      origin_keepalive_timeout = number
      origin_read_timeout      = number
    }))

    custom_header = list(object({
      name  = string
      value = string
    }))

    origin_shield_enabled = string
    origin_shield_region  = string

    connection_attempts = number
    connection_timeout  = number

  }))
  description = "One or more origins for this distribution (multiples allowed)."
}

variable "aliases" {
  type        = list(string)
  description = "Extra CNAMEs (alternate domain names), if any, for this distribution."
  default     = null
}

variable "enabled" {
  type        = bool
  description = "Whether the distribution is enabled to accept end user requests for content."
  default     = true
}

variable "is_ipv6_enabled" {
  type        = bool
  description = "Whether the IPv6 is enabled for the distribution."
  default     = false
}

variable "http_version" {
  type        = string
  description = "The maximum HTTP version to support on the distribution. Allowed values are http1.1, http2, http2and3 and http3. The default is http2."
  default     = "http2"
}

variable "comment" {
  type        = string
  description = "Any comments you want to include about the distribution."
  default     = null
}

variable "default_root_object" {
  type        = string
  description = "The object that you want CloudFront to return (for example, index.html) when an end user requests the root URL."
  default     = null
}

variable "logging_config" {
  type = list(object({
    bucket          = string
    prefix          = string
    include_cookies = bool
  }))
  description = "The logging configuration that controls how logs are written to your distribution (maximum one)."
  default     = null
}

variable "default_cache_behavior" {
  type = list(object({
    compress                   = bool
    viewer_protocol_policy     = string
    allowed_methods            = list(string)
    cached_methods             = list(string)
    target_origin_id           = string
    cache_policy_id            = string
    origin_request_policy_id   = string
    response_headers_policy_id = string
  }))
  description = "The default cache behavior for this distribution (maximum one)."
}

variable "ordered_cache_behavior" {
  type = list(object({
    path_pattern               = string
    compress                   = bool
    viewer_protocol_policy     = string
    allowed_methods            = list(string)
    cached_methods             = list(string)
    target_origin_id           = string
    cache_policy_id            = string
    origin_request_policy_id   = string
    response_headers_policy_id = string
  }))
  description = "An ordered list of cache behaviors resource for this distribution."
  default     = null
}

variable "restrictions" {
  type = list(object({
    restriction_type = string
    locations        = list(string)
  }))
  description = "The restriction configuration for this distribution (maximum one)."
  default     = null
}

variable "price_class" {
  type        = string
  description = "The price class for this distribution. One of PriceClass_All, PriceClass_200, PriceClass_100."
  default     = "PriceClass_200"
}

variable "viewer_certificate" {
  type = list(object({
    cloudfront_default_certificate = bool
    acm_certificate_arn            = string
    minimum_protocol_version       = string
    ssl_support_method             = string
  }))
  description = "The SSL configuration for this distribution (maximum one)."
}

variable "web_acl_id" {
  type        = string
  description = "A unique identifier that specifies the AWS WAF web ACL, if any, to associate with this distribution."
  default     = null
}

variable "retain_on_delete" {
  type        = bool
  description = "Disables the distribution instead of deleting it when destroying the resource through Terraform."
  default     = false
}

variable "wait_for_deployment " {
  type        = bool
  description = "If enabled, the resource will wait for the distribution status to change from InProgress to Deployed."
  default     = true
}

variable "tags_name" {
  type        = string
  description = "tags name"
  default     = null
}

# OAC
variable "oac_create" {
  type        = bool
  description = "whether Create OAC."
  default     = false
}

variable "oac_name" {
  type        = string
  description = "A name that identifies the Origin Access Control."
}

variable "description" {
  type        = string
  description = "The description of the Origin Access Control. It may be empty."
}
