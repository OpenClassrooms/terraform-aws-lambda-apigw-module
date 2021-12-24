resource "aws_iam_role" "lambda_iam_role" {
  name               = var.lambda_project_name
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
