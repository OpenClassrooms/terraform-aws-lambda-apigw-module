resource "aws_iam_role" "lambda_iam_role" {
  for_each           = toset(var.api_gateway_stages)
  name               = substr("${each.key}_${var.lambda_project_name}", 0, 64)
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


resource "aws_iam_role" "cloudwatch" {
  for_each = var.use_api_gateway == true ? toset(var.api_gateway_stages) : []
  name     = substr("${each.key}_apigw_cw_${var.lambda_project_name}", 0, 64)

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
