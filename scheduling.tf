# The scheduling part

locals {
  full_scheduling_config = var.scheduling_enabled == true ? flatten([
    for stage in var.api_gateway_stages : [
      for ck, c in var.scheduling_config : {
        stage      = stage
        rule_name  = ck
        expression = c.scheduling_expression
        input      = try(c.input, "")
      }
    ]
  ]) : []
}

resource "aws_cloudwatch_event_rule" "cloudwatch_event_rule" {
  for_each = {
    for scheduling_config in local.full_scheduling_config : "${var.lambda_project_name}_${scheduling_config.rule_name}_${scheduling_config.stage}" => scheduling_config
  }
  name                = each.key
  description         = "${each.key} cloudwatch event rule"
  schedule_expression = each.value.expression
  state               = var.scheduling_enabled ? "ENABLED" : "DISABLED"
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo,
    env              = each.key
  }, var.tags, var.default_tags)
}

resource "aws_cloudwatch_event_target" "cloudwatch_event_target" {
  for_each = {
    for scheduling_config in local.full_scheduling_config : "${var.lambda_project_name}_${scheduling_config.rule_name}_${scheduling_config.stage}" => scheduling_config
  }
  rule      = aws_cloudwatch_event_rule.cloudwatch_event_rule[each.key].name
  target_id = each.key
  arn       = aws_lambda_function.lambda_function[each.value.stage].arn
  input     = "{\"body\": ${jsonencode(each.value.input)}}"
}

resource "aws_lambda_permission" "permission_allow_cloudwatch_to_call_llambda" {
  for_each = {
    for scheduling_config in local.full_scheduling_config : "${var.lambda_project_name}_${scheduling_config.rule_name}_${scheduling_config.stage}" => scheduling_config
  }
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function[each.value.stage].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_event_rule[each.key].arn
}
