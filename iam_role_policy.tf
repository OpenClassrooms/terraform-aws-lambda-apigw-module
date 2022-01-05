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
