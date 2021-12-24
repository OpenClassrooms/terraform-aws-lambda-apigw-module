resource "aws_cloudwatch_log_group" "lambda_aws_cloudwatch_log_group" {
  name              = "/aws/lambda/${var.lambda_project_name}"
  retention_in_days = var.lambda_cloudwatch_logs_retention
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo
  }, var.tags, var.default_tags)
}

resource "aws_cloudwatch_log_group" "api_gateway_aws_cloudwatch_log_group" {
  name              = "/aws/apigateway/${var.lambda_project_name}"
  retention_in_days = var.api_gateway_cloudwatch_logs_retention
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo
  }, var.tags, var.default_tags)
}
