data "aws_cloudfront_cache_policy" "aws_managed_cachingoptimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "aws_managed_user_agent_referer_headers" {
  name = "Managed-UserAgentRefererHeaders"
}

data "aws_cloudfront_response_headers_policy" "aws_managed_security_headers_policy" {
  name = "Managed-SecurityHeadersPolicy"
}
