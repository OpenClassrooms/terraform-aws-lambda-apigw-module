# The sqs part
resource "aws_lambda_event_source_mapping" "sqs_aws_lambda_event_source_mapping" {
  for_each         = toset(var.sqs_queues_arn)
  event_source_arn = each.value
  function_name    = var.lambda_project_name
}
