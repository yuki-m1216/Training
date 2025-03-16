module "OpenSearchServerless" {
  source                 = "../../../modules/OpenSearch/serverless"
  collection_name        = "my-collection"
  collection_description = "My collection"
  collection_type        = "VECTORSEARCH"
  standby_replicas       = "ENABLED"
  collection_tags = {
    Name = "MyCollection"
  }

  security_policy_name        = "my-security-policy"
  security_policy_description = "My security policy"
  security_policy_type        = "encryption"
  security_policy = jsonencode({
    "Rules" = [
      {
        "ResourceType" = "collection",
        "Resource" = [
          "collection/my-collection"
        ],
      }
    ],
    "AWSOwendKey" = true
  })

  access_policy_name        = "my-access-policy"
  access_policy_description = "My access"
  access_policy = jsonencode({
    "Rules" = [
      {
        "ResourceType" = "index",
        "Resource" = [
          "index/,y-collection/*"
        ],
        "permission" = [
          "aos:*"
        ]
      }
    ],
    "Principal" = [
      data.aws_caller_identity.current.arn
    ]
  })
}