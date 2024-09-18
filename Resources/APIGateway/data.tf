# apigateway
data "template_file" "openapi" {
  template = file("./OpenAPI/test_apigateway.yaml")

  vars = {
    lambda_arn   = module.lambda.LambdaArn
    iam_role_arn = module.iam_for_apigateway.role_arn
  }
}

# apigateway iam
data "aws_iam_policy_document" "invokelambda" {
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [module.lambda.LambdaArn]
  }
}

# api gateway resource policy
data "aws_iam_policy_document" "apigateway_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["${module.apigateway.apigateway_execution_arn}/*"]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["${chomp(data.http.checkip.response_body)}/32"]
    }
  }
}

# myip
data "http" "checkip" {
  url = "http://ipv4.icanhazip.com/"
}

# lambda
data "archive_file" "function" {
  type        = "zip"
  source_dir  = "lambda/source"
  output_path = "lambda/upload/source.zip"
}

# acm
data "terraform_remote_state" "acm_ap_northeast_1" {
  backend = "s3"

  config = {
    bucket = "s3-terraform-state-y-mitsuyama"
    key    = "ACM.tfstate"
    region = "ap-northeast-1"
  }
}

# route53
data "terraform_remote_state" "hoste_zone_id" {
  backend = "s3"

  config = {
    bucket = "s3-terraform-state-y-mitsuyama"
    key    = "Route53.tfstate"
    region = "ap-northeast-1"
  }
}
