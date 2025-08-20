/*
マルチリージョンをfor_eachなどでやるのは以下待ち
https://github.com/hashicorp/terraform/issues/24476
*/

# ap-northeast-1
module "guard_duty" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# us-east-1
module "guard_duty_use1" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.us-east-1
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# us-east-2
module "guard_duty_use2" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.us-east-2
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# us-west-1
module "guard_duty_usw1" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.us-west-1
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# us-west-2
module "guard_duty_usw2" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.us-west-2
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# ap-south-1
module "guard_duty_aps1" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.ap-south-1
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# ap-northeast-2
module "guard_duty_apne2" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.ap-northeast-2
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# ap-northeast-3
module "guard_duty_apne3" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.ap-northeast-3
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# ap-southeast-1
module "guard_duty_apse1" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.ap-southeast-1
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# ap-southeast-2
module "guard_duty_apse2" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.ap-southeast-2
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# ca-central-1
module "guard_duty_cac1" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.ca-central-1
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# eu-central-1
module "guard_duty_euc1" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.eu-central-1
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# eu-west-1
module "guard_duty_euw1" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.eu-west-1
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# eu-west-2
module "guard_duty_euw2" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.eu-west-2
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# eu-west-3
module "guard_duty_euw3" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.eu-west-3
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# eu-north-1
module "guard_duty_eun1" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.eu-north-1
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}

# sa-east-1
module "guard_duty_sae1" {
  source = "../../../modules/GuardDuty"

  providers = {
    aws.alternate = aws.sa-east-1
  }

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}
