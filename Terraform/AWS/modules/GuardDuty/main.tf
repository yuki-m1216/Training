resource "aws_guardduty_detector" "detector" {
  provider = aws.alternate

  enable                       = var.enable
  finding_publishing_frequency = var.finding_publishing_frequency

  datasources {
    s3_logs {
      enable = var.datasources["s3_logs"]
    }
    kubernetes {
      audit_logs {
        enable = var.datasources["kubernete_audit_logs"]
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.datasources["ec2_ebs_volumes"]
        }
      }
    }
  }

  tags = {
    "Name" = var.name
  }
}
