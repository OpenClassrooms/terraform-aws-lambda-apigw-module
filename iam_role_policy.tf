resource "aws_iam_role_policy" "lambda_iam_role_policy_allow_logging_to_log_group" {
  name   = "lambda_${var.lambda_project_name}"
  role   = aws_iam_role.lambda_iam_role.name
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

resource "aws_iam_role_policy" "lambda_iam_role_policy_allow_ec2_actions" {
  count  = length(var.subnet_ids) > 0 ? 1 : 0
  name   = "lambda_ec2_${var.lambda_project_name}"
  role   = aws_iam_role.lambda_iam_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
