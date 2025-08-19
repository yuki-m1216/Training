### DynamoDB ###
resource "aws_dynamodb_table" "dynamodb_table" {
  count = var.autoscaling_enable ? 0 : 1

  name           = var.dynamodb_table
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  hash_key       = var.hash_key
  range_key      = var.range_key


  dynamic "attribute" {
    for_each = var.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  ttl {
    attribute_name = var.ttl_attribute_name
    enabled        = var.ttl_enabled
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes

    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      write_capacity     = global_secondary_index.value.write_capacity
      read_capacity      = global_secondary_index.value.read_capacity
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
    }
  }

  tags = {
    Name = var.dynamodb_table
  }
}

# AutoScaling 
/*
ignore_changesを動的に変更できなさそうなので、リソースを分けて対応する。
以下の実装待ち。
https://github.com/hashicorp/terraform/issues/24188
https://github.com/hashicorp/terraform/pull/32608
*/
resource "aws_dynamodb_table" "dynamodb_table_autoscaling" {
  count = var.autoscaling_enable ? 1 : 0

  name           = var.dynamodb_table
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  hash_key       = var.hash_key
  range_key      = var.range_key


  dynamic "attribute" {
    for_each = var.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  ttl {
    attribute_name = var.ttl_attribute_name
    enabled        = var.ttl_enabled
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes

    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      write_capacity     = global_secondary_index.value.write_capacity
      read_capacity      = global_secondary_index.value.read_capacity
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
    }
  }

  tags = {
    Name = var.dynamodb_table
  }

  lifecycle {
    ignore_changes = [
      read_capacity,
      write_capacity
    ]
  }
}

### AutoScaling ###
# read
resource "aws_appautoscaling_target" "dynamodb_table_read_target" {
  count = var.autoscaling_read ? 1 : 0

  max_capacity       = var.autoscaling_read_max_capacity
  min_capacity       = var.read_capacity
  resource_id        = "table/${aws_dynamodb_table.dynamodb_table_autoscaling[0].name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_read_policy" {
  count = var.autoscaling_read ? 1 : 0

  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_read_target[0].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_read_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_read_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_read_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = var.read_policy_target_value
  }
}

# write
resource "aws_appautoscaling_target" "dynamodb_table_write_target" {
  count = var.autoscaling_write ? 1 : 0

  max_capacity       = var.autoscaling_write_max_capacity
  min_capacity       = var.write_capacity
  resource_id        = "table/${aws_dynamodb_table.dynamodb_table_autoscaling[0].name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_write_policy" {
  count = var.autoscaling_write ? 1 : 0

  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_write_target[0].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_write_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_write_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_write_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = var.write_policy_target_value
  }
}

# AutoScaling for global secondary index 
# read
resource "aws_appautoscaling_target" "index_read_target" {
  for_each = var.autoscaling_indexes

  max_capacity       = each.value["read_max_capacity"]
  min_capacity       = each.value["read_min_capacity"]
  resource_id        = "table/${aws_dynamodb_table.dynamodb_table_autoscaling[0].name}/index/${each.key}"
  scalable_dimension = "dynamodb:index:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "index_read_policy" {
  for_each = var.autoscaling_indexes

  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.index_read_target[each.key].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.index_read_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.index_read_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.index_read_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = each.value["read_policy_target_value"]
  }
}

# write
resource "aws_appautoscaling_target" "index_write_target" {
  for_each = var.autoscaling_indexes

  max_capacity       = each.value["write_max_capacity"]
  min_capacity       = each.value["write_min_capacity"]
  resource_id        = "table/${aws_dynamodb_table.dynamodb_table_autoscaling[0].name}/index/${each.key}"
  scalable_dimension = "dynamodb:index:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "index_write_policy" {
  for_each = var.autoscaling_indexes

  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.index_write_target[each.key].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.index_write_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.index_write_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.index_write_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = each.value["write_policy_target_value"]
  }
}
