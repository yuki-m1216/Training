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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
}

# ap-southeast-2
module "EventBridge_Sender_ap-southeast-2" {
  source = "../../../modules/EventBridge"
  providers = {
    aws.alternate = aws.ap-southeast-2
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
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
  target_role_arn = module.IAM_Role_EventBridge_Sender.role_arn

  depends_on = [module.EventBridge_Receiver]
}
