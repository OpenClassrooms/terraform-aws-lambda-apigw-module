output "api_path" {
  description = "api path"
  value       = var.api_gateway_path
}

output "api_keys_paths" {
  description = "api keys path on SSM/ParameterStore"
  value = tomap({
    for k, v in aws_ssm_parameter.api_key : k => v.name
  })
}

output "lambda_function_arn_list" {
  description = "The arn of the lambda function"
  value = tomap({
    for k, v in aws_lambda_function.lambda_function : k => v.arn
  })
}
