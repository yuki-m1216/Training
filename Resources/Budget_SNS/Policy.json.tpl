{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSBudgetsSNSPublishingPermissions",
            "Effect": "Allow",
            "Principal": {
              "Service": "budgets.amazonaws.com"
            },
            "Action": "SNS:Publish",
            "Resource": "arn:aws:sns:ap-northeast-1:${account_id}:Budget_SNS_topic"
        }
    ]
}