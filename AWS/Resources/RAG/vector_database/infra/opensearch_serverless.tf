module "OpenSearchServerless" {
  source                 = "../../../../modules/OpenSearch/serverless"
  collection_name        = "bedrock-faq"
  collection_description = "bedrock-faq"
  collection_type        = "VECTORSEARCH"
  standby_replicas       = "ENABLED"
  collection_tags = {
    Name = "bedrock-faq"
  }

  encryption_security_policy_name        = "bedrock-faq-enc-security"
  encryption_security_policy_description = "bedrock-faq-enc-security"
  encryption_security_policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection",
        Resource = [
          "collection/bedrock-faq"
        ],
      }
    ],
    AWSOwnedKey = true
  })

  network_security_policy_name        = "bedrock-faq-net-security"
  network_security_policy_description = "bedrock-faq-net-security"
  network_security_policy = jsonencode([{
    Rules = [
      {
        ResourceType = "collection",
        Resource = [
          "collection/bedrock-faq"
        ],
      }
    ]
    AllowFromPublic = true
  }])

  access_policy_name        = "bedrock-faq-access-policy"
  access_policy_description = "bedrock-faq access policy"
  access_policy = jsonencode([{
    Rules = [
      {
        ResourceType = "index",
        Resource = [
          "index/bedrock-faq/*"
        ],
        Permission = [
          "aoss:*"
        ]
      }
    ],
    Principal = [
      data.aws_caller_identity.current.arn,
      aws_iam_role.this.arn, 
      aws_iam_role.opensearch_access_role.arn
    ]
  }])
}