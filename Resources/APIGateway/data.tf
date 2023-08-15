data "template_file" "openapi" {
  template = file("./OpenAPI/test_apigateway.yaml")

  vars = {
    lambda_arn   = "arn:aws:lambda:ap-northeast-1:444274348434:function:test"
    iam_role_arn = module.iam_for_apigateway.role_arn
  }
}

data "aws_iam_policy_document" "invokelambda" {
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = ["arn:aws:lambda:ap-northeast-1:444274348434:function:test"]
  }
}
