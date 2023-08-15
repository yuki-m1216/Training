data "template_file" "openapi" {
  template = file("./OpenAPI/test_apigateway.yaml")

  vars = {
    lambda_arn = "arn:aws:lambda:ap-northeast-1:444274348434:function:test"
  }
}
