module "dynamodb" {
  source = "../../../modules/DynamoDB"

  ### DynamoDB ###
  dynamodb_table = "Test-DynamoDB"
  billing_mode   = "PROVISIONED"
  hash_key       = "UserId"
  range_key      = "GameTitle"

  attributes = [
    {
      name = "UserId"
      type = "S"
    },
    {
      name = "GameTitle"
      type = "S"
    },
    {
      name = "TopScore"
      type = "N"
    },
  ]

  global_secondary_indexes = [
    {
      name               = "GameTitleIndex"
      hash_key           = "GameTitle"
      range_key          = "TopScore"
      write_capacity     = 10
      read_capacity      = 10
      projection_type    = "INCLUDE"
      non_key_attributes = ["UserId"]
    }
  ]

  # ### AutoScaling ###
  # autoscaling_enable = true
  # autoscaling_read   = true
  # autoscaling_write  = true
}


resource "aws_dynamodb_table_item" "example_item" {
  table_name = module.dynamodb.dynamodb_table_id
  hash_key   = module.dynamodb.dynamodb_table_hash_key
  range_key  = module.dynamodb.dynamodb_table_range_key

  item = jsonencode(
    {
      "UserId" : { "S" : "1" },
      "GameTitle" : { "S" : "TestGame" },
      "TopScore" : { "N" : "1111" },
    }

  )
}
