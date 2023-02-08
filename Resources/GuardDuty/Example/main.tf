module "guard_duty" {
  source = "../../../modules/GuardDuty"

  enable = true
  datasources = {
    s3_logs              = true
    kubernete_audit_logs = false
    ec2_ebs_volumes      = true
  }
  name = "Example-GuardDuty"
}
