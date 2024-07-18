locals {
  custom_authorizer        = var.api_gateway_authorization == "CUSTOM" ? 1 : 0
  custom_authorizer_stages = var.api_gateway_authorization == "CUSTOM" ? toset(var.api_gateway_stages) : []
}

resource "aws_lambda_function" "lambda_function_custom_authorizer" {

  for_each = local.custom_authorizer_stages

  function_name = each.key == "no_stage" ? var.lambda_custom_authorizer_name : "${substr(var.lambda_custom_authorizer_name, 0, 50)}_${each.key}"
  role          = aws_iam_role.lambda_iam_role_custom_authorizer[0].arn
  handler       = "${var.lambda_custom_authorizer_script_name}.${var.lambda_custom_authorizer_handler}"
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

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = var.environment_variables[each.key]
  }

  depends_on = [
    aws_s3_object.code_base_package
  ]

  lifecycle {
    ignore_changes = [source_code_hash]
  }
}

resource "aws_api_gateway_authorizer" "custom_authorizer" {

  for_each = local.custom_authorizer_stages

  name                   = "${var.lambda_project_name}_${each.key}"
  rest_api_id            = aws_api_gateway_rest_api.api_gw_rest_api[each.key].id
  authorizer_uri         = aws_lambda_function.lambda_function_custom_authorizer[each.key].invoke_arn
  authorizer_credentials = aws_iam_role.invocation_role_custom_authorizer[0].arn
  type                   = "REQUEST"
  identity_source        = "method.request.header.Authorization"
  // identity_source        = "method.request.header.authorizationToken,method.request.querystring.API_KEY"
  // authorizer_credentials = var.api_gateway_authorizer_credentials
}


resource "aws_iam_role" "invocation_role_custom_authorizer" {

  count = local.custom_authorizer

  name = "${var.lambda_project_name}_gw_auth_invocation"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "ApiGWCustomAuthAPIGW"
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "ApiGWCustomAuthLambda"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "invocation_policy_custom_authorizer" {

  for_each = local.custom_authorizer_stages

  name = "${var.lambda_project_name}_custom_authorizer_${each.key}"
  role = aws_iam_role.invocation_role_custom_authorizer[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.lambda_function_custom_authorizer[each.key].arn}"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "lambda_custom_authorizer_aws_cloudwatch_log_group" {

  for_each = local.custom_authorizer_stages

  name = each.key == "no_stage" ? "/aws/lambda/${var.lambda_custom_authorizer_name}" : "/aws/lambda/${substr(var.lambda_custom_authorizer_name, 0, 50)}_${each.key}"

  retention_in_days = var.lambda_cloudwatch_logs_retention
  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo
  }, var.tags, var.default_tags)
}


resource "aws_iam_role" "lambda_iam_role_custom_authorizer" {

  count = local.custom_authorizer

  name               = substr("lambda_${var.lambda_custom_authorizer_name}", 0, 64)
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = merge({
    module           = "apigw_lambda",
    lambda_code_repo = var.lambda_code_repo
  }, var.tags, var.default_tags)
}

resource "aws_iam_role_policy" "lambda_iam_role_custom_authorizer_policy_allow_logging_to_log_group" {

  count = local.custom_authorizer

  name   = "lambda_${var.lambda_custom_authorizer_name}"
  role   = aws_iam_role.lambda_iam_role_custom_authorizer[0].name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_iam_role_policy_ssm" {

  count = local.custom_authorizer

  name   = "lambda_ssm_${var.lambda_project_name}"
  role   = aws_iam_role.lambda_iam_role_custom_authorizer[0].name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameterHistory",
        "ssm:ListTagsForResource",
        "ssm:GetParametersByPath",
        "ssm:GetParameters",
        "ssm:GetParameter"
        ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/vault/aws/apigateway_authorizer/*"
    }
  ]
}
EOF
}
