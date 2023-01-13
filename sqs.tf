# The sqs part
resource "aws_lambda_event_source_mapping" "sqs_aws_lambda_event_source_mapping" {
  count            = var.sqs_enabled ? 1 : 0
  event_source_arn = each.value
  function_name    = var.lambda_project_name
}
