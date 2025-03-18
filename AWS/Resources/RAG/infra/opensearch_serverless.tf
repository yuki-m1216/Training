module "OpenSearchServerless" {
  source                 = "../../../modules/OpenSearch/serverless"
  collection_name        = "my-collection"
  collection_description = "My collection"
  collection_type        = "VECTORSEARCH"
  standby_replicas       = "ENABLED"
  collection_tags = {
    Name = "MyCollection"
  }

  encryption_security_policy_name        = "my-encryption-security-policy"
  encryption_security_policy_description = "my encryption security policy"
  encryption_security_policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection",
        Resource = [
          "collection/my-collection"
        ],
      }
    ],
    AWSOwnedKey = true
  })

  network_security_policy_name        = "my-network-security-policy"
  network_security_policy_description = "My network security policy"
  network_security_policy = jsonencode([{
    Rules = [
      {
        ResourceType = "collection",
        Resource = [
          "collection/my-collection"
        ],
      }
    ]
    AllowFromPublic = true
  }])

  access_policy_name        = "my-access-policy"
  access_policy_description = "My access"
  access_policy = jsonencode([{
    Rules = [
      {
        ResourceType = "index",
        Resource = [
          "index/my-collection/*"
        ],
        Permission = [
          "aoss:*"
        ]
      }
    ],
    Principal = [
      data.aws_caller_identity.current.arn
    ]
  }])
}