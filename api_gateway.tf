locals {
  api_gateway_stages                    = var.use_api_gateway == true ? toset(var.api_gateway_stages) : []
  api_gateway_stages_with_schema        = var.api_gateway_validation_schema_enabled == true ? local.api_gateway_stages : []
  api_gateway_default_authorizer_stages = var.api_gateway_authorization == "CUSTOM" ? [] : local.api_gateway_stages
  api_gateway_custom_authorizer_stages  = var.api_gateway_authorization == "CUSTOM" ? local.api_gateway_stages : []
  aws_api_gateway_method_proxy          = var.api_gateway_authorization == "CUSTOM" ? aws_api_gateway_method.proxy_custom_authorizer : aws_api_gateway_method.proxy

  api_gateway_keys = var.use_api_gateway_api_key == true ? (length(var.api_gateway_api_key_list) == 0 ? flatten([
    for stage in local.api_gateway_stages : {
      stage    = "${stage}"
      key_name = "${stage}"
    }
    ]) : flatten([
    for key in var.api_gateway_api_key_list : [
      for stage in local.api_gateway_stages : {
        stage    = "${stage}"
        key_name = "${key}_${stage}"
      }
    ]])
  ) : []


  api_gateway_keys_map = {
    for item in local.api_gateway_keys : item.key_name => item
  }

}

resource "aws_api_gateway_rest_api" "api_gw_rest_api" {
  for_each    = var.use_api_gateway == true ? toset(var.api_gateway_stages) : []
  name        = "${var.lambda_project_name}_${each.key}"
  description = "API Gateway REST Api for ${var.lambda_project_name} for ${each.key} stage"
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo
  }, var.tags, var.default_tags)
}

# Mapping our custom domains to the API stages
resource "aws_api_gateway_base_path_mapping" "api-gw_base_path_mapping" {

  for_each = local.api_gateway_stages

  api_id      = aws_api_gateway_rest_api.api_gw_rest_api[each.key].id
  stage_name  = aws_api_gateway_stage.api_gw_stage[each.key].stage_name
  domain_name = var.api_gateway_domain_name_mapping[each.key]
  base_path   = var.api_gateway_path
  depends_on = [
    aws_api_gateway_deployment.api_gw_deployment,
  ]
}

resource "aws_api_gateway_method" "proxy" {

  for_each = local.api_gateway_default_authorizer_stages

  rest_api_id      = aws_api_gateway_rest_api.api_gw_rest_api[each.key].id
  resource_id      = aws_api_gateway_rest_api.api_gw_rest_api[each.key].root_resource_id
  http_method      = var.api_gateway_http_method
  authorization    = var.api_gateway_authorization
  api_key_required = var.use_api_gateway_api_key
  request_parameters = {
    "method.request.path.proxy" = true
  }
  request_models = var.api_gateway_validation_schema_enabled ? {
    "${var.api_gateway_validation_schema_content_type}" = aws_api_gateway_model.api_gw_model[each.key].name
  } : {}

  request_validator_id = var.api_gateway_validation_schema_enabled ? aws_api_gateway_request_validator.api_gw_schema_validator[each.key].id : null
}

resource "aws_api_gateway_method" "proxy_custom_authorizer" {

  for_each = local.api_gateway_custom_authorizer_stages

  rest_api_id      = aws_api_gateway_rest_api.api_gw_rest_api[each.key].id
  resource_id      = aws_api_gateway_rest_api.api_gw_rest_api[each.key].root_resource_id
  http_method      = var.api_gateway_http_method
  authorization    = var.api_gateway_authorization
  authorizer_id    = aws_api_gateway_authorizer.custom_authorizer[each.key].id
  api_key_required = var.use_api_gateway_api_key
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "lambda_integration" {

  for_each = local.api_gateway_stages

  rest_api_id = aws_api_gateway_rest_api.api_gw_rest_api[each.key].id
  resource_id = local.aws_api_gateway_method_proxy[each.key].resource_id
  http_method = local.aws_api_gateway_method_proxy[each.key].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function[each.key].invoke_arn
}

resource "aws_api_gateway_deployment" "api_gw_deployment" {

  for_each = local.api_gateway_stages

  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    local.aws_api_gateway_method_proxy
  ]

  rest_api_id = aws_api_gateway_rest_api.api_gw_rest_api[each.key].id

  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.api_gw_rest_api[each.key].id,
      var.api_gateway_authorization,
      var.api_gateway_http_method,
      aws_api_gateway_integration.lambda_integration[each.key].id,
      aws_api_gateway_method.proxy[each.key].request_models,
      aws_api_gateway_method.proxy[each.key].request_validator_id,
    ]))
  }

}

resource "aws_api_gateway_stage" "api_gw_stage" {

  for_each = local.api_gateway_stages

  deployment_id = aws_api_gateway_deployment.api_gw_deployment[each.key].id
  rest_api_id   = aws_api_gateway_rest_api.api_gw_rest_api[each.key].id
  stage_name    = each.key
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_aws_cloudwatch_log_group[each.key].arn
    format          = var.apigw_cloudwatch_logs_format
  }
  depends_on = [aws_cloudwatch_log_group.api_gateway_aws_cloudwatch_log_group]
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo
  }, var.tags, var.default_tags)
}


resource "aws_lambda_permission" "apigw-lambda-permission" {
  for_each      = local.api_gateway_stages
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gw_rest_api[each.key].execution_arn}/*/*"
}

resource "aws_api_gateway_api_key" "api_key" {
  for_each = local.api_gateway_keys_map
  name     = "${var.lambda_project_name}_${each.value.key_name}_api_key"
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo
  }, var.tags, var.default_tags)
}

resource "aws_api_gateway_usage_plan" "api_usage_plan" {
  for_each = local.api_gateway_keys_map
  name     = "api_usage_plan_${var.lambda_project_name}_${each.value.key_name}"
  api_stages {
    api_id = aws_api_gateway_rest_api.api_gw_rest_api[each.value.stage].id
    stage  = each.value.stage
  }
  depends_on = [
    aws_api_gateway_deployment.api_gw_deployment,
    aws_api_gateway_stage.api_gw_stage
  ]
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo
  }, var.tags, var.default_tags)
}

resource "aws_api_gateway_usage_plan_key" "api_usage_plan_key" {
  for_each      = local.api_gateway_keys_map
  key_id        = aws_api_gateway_api_key.api_key[each.value.key_name].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_usage_plan[each.value.key_name].id
}

resource "aws_api_gateway_model" "api_gw_model" {
  for_each     = local.api_gateway_stages_with_schema
  rest_api_id  = aws_api_gateway_rest_api.api_gw_rest_api[each.key].id
  name         = "${var.lambda_project_name}SchemaValidation"
  description  = "JSON schema for validation"
  content_type = var.api_gateway_validation_schema_content_type

  schema = var.api_gateway_validation_schema
}

resource "aws_api_gateway_request_validator" "api_gw_schema_validator" {
  for_each              = local.api_gateway_stages_with_schema
  name                  = "${var.lambda_project_name}BodyValidator"
  rest_api_id           = aws_api_gateway_rest_api.api_gw_rest_api[each.key].id
  validate_request_body = true
}
