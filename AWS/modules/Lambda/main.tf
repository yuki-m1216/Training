# Lambda
resource "aws_lambda_function" "main" {
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

  depends_on = [aws_cloudwatch_log_group.main]
}

# Lambda permission
resource "aws_lambda_permission" "main" {
  count = var.create_lambda_permission ? 1 : 0

  provider      = aws.alternate
  statement_id  = var.statement_id
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = var.principal
  source_arn    = "${var.source_arn}/*"
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.log_group_retention_in_days

  tags = {
    Name = "/aws/lambda/${var.lambda_function_name}"
  }
}
