terraform {
  required_providers {
    aws = {
      # source = "hashicorp/aws"
      configuration_aliases = [aws.alternate]
    }
  }
}

# variable 
# Lambda
variable "lambda_filename" {}
variable "lambda_function_name" {}
variable "lambda_role" {
  default = null
}
variable "handler" {}
variable "runtime" {}
variable "environment_variables" {
  type    = map(any)
  default = null
}

# Lambda permission
variable "statement_id" {
  default = null
}
variable "principal" {
  default = null
}
variable "source_arn" {
  default = null
}

# Lambda
resource "aws_lambda_function" "lambda" {
  provider      = aws.alternate
  filename      = var.lambda_filename
  function_name = var.lambda_function_name
  role          = var.lambda_role
  handler       = var.handler

  source_code_hash = filebase64sha256(var.lambda_filename)

  runtime = var.runtime

  environment {
    variables = var.environment_variables
  }
}

# Lambda permission
resource "aws_lambda_permission" "lambda_permission" {
  provider      = aws.alternate
  statement_id  = var.statement_id
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = var.principal
  source_arn    = var.source_arn
}

output "LambdaArn" {
  value = aws_lambda_function.lambda.arn
}