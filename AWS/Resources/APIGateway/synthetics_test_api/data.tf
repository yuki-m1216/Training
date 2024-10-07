# apigateway
data "template_file" "openapi" {
  template = file("./OpenAPI/test_apigateway.yaml")

  vars = {
    lambda_arn   = module.lambda.LambdaArn
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

# lambda
data "archive_file" "function" {
  type        = "zip"
  source_dir  = "lambda/dist"
  output_path = "lambda/upload/source.zip"
}
