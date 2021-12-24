resource "aws_apigatewayv2_api" "apigwv2_api" {
  count         = var.use_api_gateway == true ? 1 : 0
  name          = "${var.lambda_project_name}_api"
  protocol_type = "HTTP"
  description   = "${var.lambda_project_name} API"
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo
  }, var.tags, var.default_tags)
}

resource "aws_apigatewayv2_integration" "apigwv2_api_integration" {
  for_each                  = var.use_api_gateway == true ? toset(var.api_gateway_stages) : []
  api_id                    = aws_apigatewayv2_api.apigwv2_api[0].id
  description               = "${var.lambda_project_name} lambda apigwv2_api_integration for ${each.key} stage"
  integration_type          = "AWS_PROXY"
  connection_type           = "INTERNET"
  content_handling_strategy = "CONVERT_TO_TEXT"
  integration_method        = "POST"
  integration_uri           = aws_lambda_function.lambda_function[each.key].invoke_arn
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "apigwv2_route" {
  for_each  = var.use_api_gateway == true ? toset(var.api_gateway_stages) : []
  api_id    = aws_apigatewayv2_api.apigwv2_api[0].id
  route_key = "ANY ${var.api_gateway_path}"
  target    = "integrations/${aws_apigatewayv2_integration.apigwv2_api_integration[each.key].id}"
}

resource "aws_apigatewayv2_deployment" "apigwv2_deployment" {
  for_each    = var.use_api_gateway == true ? toset(var.api_gateway_stages) : []
  api_id      = aws_apigatewayv2_api.apigwv2_api[0].id
  description = "${var.lambda_project_name} API deployment for ${each.key} stage"

  # triggers = {
  #   "redeployment" = sha256(var.body)
  # }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "apigwv2_stage" {
  for_each      = var.use_api_gateway == true ? toset(var.api_gateway_stages) : []
  api_id        = aws_apigatewayv2_api.apigwv2_api[0].id
  name          = each.key
  description   = "${each.key} stage for ${var.lambda_project_name} API"
  deployment_id = aws_apigatewayv2_deployment.apigwv2_deployment[each.key].id
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_aws_cloudwatch_log_group.arn
    format          = var.apigw_cloudwatch_logs_format
  }
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo
  }, var.tags, var.default_tags)
}

resource "aws_apigatewayv2_api_mapping" "apigwv2_api_mapping" {
  for_each    = var.use_api_gateway == true ? toset(var.api_gateway_stages) : []
  api_id      = aws_apigatewayv2_api.apigwv2_api[0].id
  domain_name = var.api_gateway_custom_domain
  stage       = aws_apigatewayv2_stage.apigwv2_stage[each.key].id
}

resource "aws_lambda_permission" "apigw-lambda-permission" {
  for_each      = var.use_api_gateway == true ? toset(var.api_gateway_stages) : []
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API. 
  source_arn = "${aws_apigatewayv2_api.apigwv2_api[0].execution_arn}/*/*"
}

resource "aws_api_gateway_api_key" "api_key" {
  for_each = var.use_api_gateway == true && var.api_gateway_api_key == true ? toset(var.api_gateway_stages) : []
  name     = "${var.lambda_project_name}_${each.key}_api_key"
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo
  }, var.tags, var.default_tags)
}

resource "aws_api_gateway_usage_plan" "api_usage_plan" {
  for_each = var.use_api_gateway == true && var.api_gateway_api_key == true ? toset(var.api_gateway_stages) : []
  name     = "api_usage_plan_${var.lambda_project_name}_${each.key}"

  api_stages {
    api_id = aws_apigatewayv2_api.apigwv2_api[0].id
    stage  = each.key
  }

  depends_on = [
    aws_apigatewayv2_deployment.apigwv2_deployment
  ]
}

resource "aws_api_gateway_usage_plan_key" "api_usage_plan_key" {
  for_each      = var.use_api_gateway == true && var.api_gateway_api_key == true ? toset(var.api_gateway_stages) : []
  key_id        = aws_api_gateway_api_key.api_key[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_usage_plan[each.key].id
}
