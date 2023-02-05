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
      write_capacity     = 5
      read_capacity      = 5
      projection_type    = "INCLUDE"
      non_key_attributes = ["UserId"]
    }
  ]

  ### AutoScaling ###
  autoscaling_enable = true
  autoscaling_read   = true
  autoscaling_write  = true

  autoscaling_indexes = {
    GameTitleIndex = {
      # read
      read_max_capacity        = 20
      read_min_capacity        = 5
      read_policy_target_value = 70

      # write
      write_max_capacity        = 20
      write_min_capacity        = 5
      write_policy_target_value = 70
    }
  }
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
