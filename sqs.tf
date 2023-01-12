# The sqs part
locals {
  sqs_queues = var.sqs_enabled == true ? toset(var.sqs_queues_arn) : []
}

resource "aws_lambda_event_source_mapping" "example" {
  for_each         = local.sqs_queues
  event_source_arn = each.value
  function_name    = var.lambda_project_name
}
