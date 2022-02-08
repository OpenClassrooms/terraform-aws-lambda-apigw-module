# The scheduling part
resource "aws_cloudwatch_event_rule" "cloudwatch_event_rule" {
  for_each            = var.scheduling_enabled == true ? toset(var.api_gateway_stages) : []
  name                = "${var.lambda_project_name}_${each.key}_cw_ev_rule"
  description         = "${var.lambda_project_name}_${each.key} cloudwatch event rule"
  schedule_expression = var.schedule_expression
  is_enabled          = var.scheduling_enabled
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo,
    env              = each.key
  }, var.tags, var.default_tags)
}

resource "aws_cloudwatch_event_target" "cloudwatch_event_target" {
  for_each  = var.scheduling_enabled == true ? toset(var.api_gateway_stages) : []
  rule      = aws_cloudwatch_event_rule.cloudwatch_event_rule[each.key].name
  target_id = "${var.lambda_project_name}_${each.key}"
  arn       = aws_lambda_function.lambda_function[each.key].arn
}

resource "aws_lambda_permission" "permission_allow_cloudwatch_to_call_llambda" {
  for_each      = var.scheduling_enabled == true ? toset(var.api_gateway_stages) : []
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_event_rule[each.key].arn
}
