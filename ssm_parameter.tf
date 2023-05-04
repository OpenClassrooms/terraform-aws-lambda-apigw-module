resource "aws_ssm_parameter" "api_key" {
  for_each = var.use_api_gateway == true && var.store_api_keys_in_ssm == true ? toset(var.api_gateway_stages) : []
  name     = "${var.api_keys_prefix_in_ssm}/${each.key}/${var.lambda_project_name}/api_key"
  type     = "SecureString"
  value    = aws_api_gateway_api_key.api_key[each.key].value
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo,
    env              = each.key
  }, var.tags, var.default_tags)
}
