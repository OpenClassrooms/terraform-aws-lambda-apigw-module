resource "aws_lambda_function" "lambda_function" {
  for_each      = toset(var.api_gateway_stages)
  function_name = "${var.lambda_project_name}_${each.key}"
  role          = aws_iam_role.lambda_iam_role.arn
  handler       = "${var.lambda_script_name}.${var.lambda_handler}"
  runtime       = var.lambda_runtime
  s3_bucket     = var.lambda_codebase_bucket
  s3_key        = var.lambda_codebase_bucket_s3_key
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo,
    env              = each.key
  }, var.tags, var.default_tags)

  environment {
    variables = var.environment_variables[each.key]
  }

  depends_on = [
    aws_s3_object.code_base_package
  ]

  lifecycle {
    ignore_changes = [last_modified, source_code_hash, source_code_size, version, qualified_arn]
  }
}
