# terraform {
#   required_version = ">= 0.13.0"
#   backend "s3" {
#     bucket = "s3-terraform-state-y-mitsuyama"
#     region = "ap-northeast-1"
#     key = "ConsoleLoginAlarmLambda.tfstate"
#     encrypt = true
#   }
# }

# IAM Role
module "IAM_Role_Lambda" {
  source      = "../../../modules/IAM/Role"
  create_role = true
  role_name   = "ConsoleLoginAlarmLambdaRole"
  identifiers = "lambda.amazonaws.com"
  policies    = local.Lambdapolicies
}

locals {
  Lambdapolicies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

# # IAM Policy
# data "aws_iam_policy" "LambdaBasicExecutionRole" {
#   arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# # IAM Attachment
# locals {
#   LambdaRoleName = [
#     module.IAM_Role_Lambda.RoleName
#   ]
# }

# module "IAM_Attachment_Lambda" {
#   source = "../../../modules/IAM/Attachment"
#   for_each = {for i in local.LambdaRoleName : i => i}
#   attachment_role_name = each.value
#   policy_arn = data.aws_iam_policy.LambdaBasicExecutionRole.arn
# }



data "archive_file" "function" {
  type        = "zip"
  source_dir  = "lambda/source"
  output_path = "lambda/upload/source.zip"
}

module "Lambda" {
  source = "../../../modules/Lambda"
  providers = {
    aws.alternate = aws
  }
  lambda_filename      = data.archive_file.function.output_path
  lambda_function_name = "ConsoleLoginAlarm"
  lambda_role          = module.IAM_Role_Lambda.RoleArn
  handler              = "ConsoleAlarm.lambda_handler"
  runtime              = "python3.9"
  environment_variables = {
    webhookURL = data.aws_ssm_parameter.webhookURL.value
  }

  statement_id = "AllowExecutionFromCloudWatch"
  principal    = "events.amazonaws.com"
  source_arn   = module.EventBridge_Receiver.RuleArn
}

data "aws_ssm_parameter" "webhookURL" {
  name = "webhookURL"
}


# EventBridge
# Receiver
# ap-northeast-1
module "EventBridge_Receiver" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws
  }
  # rule
  rule_name        = "ConsoleLoginEvent"
  rule_description = "ConsoleLogin Event"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent"
  }

  # target
  target_arn = module.Lambda.LambdaArn
  # Examle input_transformer
  #   input_transformer_input_paths = {
  #       instance = "$.detail.instance",
  #       status   = "$.detail.status",
  #     }
  #   input_transformer_input_template = <<EOF
  # {
  #   "instance_id": <instance>,
  #   "instance_status": <status>
  # }
  # EOF

  # evntbus  
  create_event_bus = true
  event_bus_name   = "eventbus_receiver"
}


# IAM Role
module "IAM_Role_EventBridge_Sender" {
  source        = "../../../modules/IAM/Role"
  create_role   = true
  role_name     = "ConsoleLoginAlarmEventBridgeSenderRole"
  identifiers   = "events.amazonaws.com"
  create_policy = true
  policy_name   = "EventBridgeSenderPolicy"
  policy        = data.aws_iam_policy_document.EventBridgeSender.json
  policies      = local.EventBridgeSenderpolicies
}

# # IAM Policy
# module "IAM_Policy_EventBridge_Sender" {
#   source = "../../../modules/IAM/Policy"
#   policy_name = "EventBridgeSenderPolicy"
#   policy = data.aws_iam_policy_document.EventBridgeSender.json 
#   # attachment_role_name = module.IAM_Role.RoleName
# }

# IAM Policy Document
data "aws_iam_policy_document" "EventBridgeSender" {
  statement {
    actions = [
      "events:PutEvents"
    ]
    resources = [module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]]
  }
}

# IAM Attachment
locals {
  EventBridgeSenderpolicies = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/EventBridgeSenderPolicy"
  ]
}

# module "IAM_Attachment_EventBridge" {
#   source = "../../../modules/IAM/Attachment"
#   for_each = {for i in local.EventBridgeRoleName : i => i}
#   attachment_role_name = each.value
#   policy_arn = module.IAM_Policy_EventBridge_Sender.PolicyArn
# }

# Sender
# ap-northeast-1
module "EventBridge_Sender_ap-northeast-1" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}


# us-east-1
module "EventBridge_Sender_us-east-1" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.us-east-1
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# us-east-2
module "EventBridge_Sender_us-east-2" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.us-east-2
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# us-west-1
module "EventBridge_Sender_us-west-1" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.us-west-1
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# us-west-2
module "EventBridge_Sender_us-west-2" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.us-west-2
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# ap-south-1
module "EventBridge_Sender_ap-south-1" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.ap-south-1
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# ap-northeast-2
module "EventBridge_Sender_ap-northeast-2" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.ap-northeast-2
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# ap-southeast-1
module "EventBridge_Sender_ap-southeast-1" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.ap-southeast-1
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# ca-central-1
module "EventBridge_Sender_ca-central-1" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.ca-central-1
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# eu-central-1
module "EventBridge_Sender_eu-central-1" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.eu-central-1
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# eu-west-1
module "EventBridge_Sender_eu-west-1" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.eu-west-1
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# eu-west-2
module "EventBridge_Sender_eu-west-2" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.eu-west-2
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# eu-west-3
module "EventBridge_Sender_eu-west-3" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.eu-west-3
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# eu-north-1
module "EventBridge_Sender_eu-north-1" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.eu-north-1
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}

# sa-east-1
module "EventBridge_Sender_sa-east-1" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.sa-east-1
  }
  # rule
  rule_name        = "ConsoleLoginEvent_Sender"
  rule_description = "ConsoleLogin Event Sender"
  event_pattern = jsonencode(
    {
      "detail-type" : [
        "AWS Console Sign In via CloudTrail"
      ]
    }
  )
  is_enabled = true
  rule_tags = {
    Name = "ConsoleLoginEvent_Sender"
  }

  # target
  target_arn      = module.EventBridge_Receiver.Eventbridge_Eventbus_Arn[0]
  target_role_arn = module.IAM_Role_EventBridge_Sender.RoleArn
}
