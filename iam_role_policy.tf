resource "aws_iam_role_policy" "lambda_iam_role_policy_allow_logging_to_log_group" {
  for_each = toset(var.api_gateway_stages)
  name     = "${each.key}_lambda_${var.lambda_project_name}"
  role     = aws_iam_role.lambda_iam_role[each.key].name
  policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "${aws_cloudwatch_log_group.lambda_aws_cloudwatch_log_group[each.key].arn}:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  for_each = var.use_api_gateway == true ? toset(var.api_gateway_stages) : []
  name     = "${each.key}_cw_${var.lambda_project_name}"
  role     = aws_iam_role.cloudwatch[each.key].id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
