# Prerequisite before using the module
resource "aws_s3_bucket" "my-lambda-codebase-bucket" {
  bucket = "my-test-lambda-codebase-bucket"

  tags = var.tags
}

resource "aws_s3_bucket_acl" "my-lambda-codebase-bucket-acl" {
  bucket = aws_s3_bucket.my-lambda-codebase-bucket.id
  acl    = "private"
}

# we need a unique api-gateway account to allow api gateway to send logs in cloudwatch
resource "aws_api_gateway_account" "api-gw-account" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch_iam_role.arn
}

# Attach an iam role to aws_api_gateway_account
resource "aws_iam_role" "cloudwatch_iam_role" {
  name = "apigw_cloudwatch_iam_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ApiGWCloudwatchIamRolePolicy",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags               = var.tags
}

# Attach a role policy to the previous role
resource "aws_iam_role_policy" "apigw_to_cloudwatch_role_policy" {
  name = "apigw_to_cloudwatch_role_policy"
  role = aws_iam_role.cloudwatch_iam_role.id

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

# Not mandatory, but useful

# First, we declare a pretty domain name for the API Gateway
resource "aws_api_gateway_domain_name" "apigw_domain_name_name" {
  for_each        = var.apigw_domain_name_mapping
  domain_name     = each.value
  certificate_arn = aws_acm_certificate.apigw_certificate[each.key].arn
  security_policy = "TLS_1_2"
  endpoint_configuration {
    types = ["EDGE"]
  }
  tags = var.tags
}

# Then, we need a DNS name for the api gateway
resource "cloudflare_record" "api-gw" {
  for_each = var.apigw_domain_name_mapping
  zone_id  = var.cloudflare_zone_id
  name     = each.value
  value    = aws_api_gateway_domain_name.apigw_domain_name_name[each.key].cloudfront_domain_name
  type     = "CNAME"
  ttl      = 1
  proxied  = false
}


# Next need a TLS Certificate for our API Gateway custom domain
resource "aws_acm_certificate" "apigw_certificate" {
  # Cert must be in us-east-1 for API-GW custom domain: https://aws.amazon.com/premiumsupport/knowledge-center/custom-domain-name-amazon-api-gateway/?nc1=h_ls
  provider          = aws.north-virginia
  for_each          = var.apigw_domain_name_mapping
  domain_name       = each.value
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}

# Fianlly a DNS record for the certificate validation
resource "cloudflare_record" "api-gw-cert-validation" {
  for_each = aws_acm_certificate.apigw_certificate
  zone_id  = var.cloudflare_zone_id
  name     = each.value.domain_validation_options.*.resource_record_name[0]
  # We need to remove the last dot to avoid infinite plan diff :-S
  value   = trimsuffix(each.value.domain_validation_options.*.resource_record_value[0], ".")
  type    = each.value.domain_validation_options.*.resource_record_type[0]
  ttl     = 1
  proxied = false
}



module "my_example_module" {
  source                           = "../" # in this example, this is a local module. For real use, source will be "OpenClassrooms/lambda-apigw-module/aws"
  lambda_project_name              = "test"
  lambda_script_name               = "main"
  lambda_handler                   = "main"
  lambda_runtime                   = "python3.8"
  lambda_code_repo                 = "https://github.com/xxx/myrepo"
  lambda_codebase_bucket           = aws_s3_bucket.my-lambda-codebase-bucket.bucket
  lambda_cloudwatch_logs_retention = 7
  environment_variables = {
    "staging" = {
      MY_GREAT_VARIABLE = "bob",
    }
    "production" = {
      MY_GREAT_VARIABLE = "alice",
    }
  }
  use_api_gateway                       = true
  use_api_gateway_api_key               = true
  store_api_keys_in_ssm                 = true
  api_gateway_domain_name_mapping       = var.apigw_domain_name_mapping
  api_gateway_path                      = "mypath"
  api_gateway_stages                    = ["production", "staging"]
  api_gateway_cloudwatch_logs_retention = 7
  send_logs_to_newrelic                 = true
  newrelic_log_ingestion_function_arn   = "xxx"
  scheduling_enabled                    = true
  scheduling_config = {
    "every_ten_minutes" = {
      scheduling_expression = "cron(*/10 * * * ? *)",
      input                 = "{\"foo\":{\"bar\": [1,2]}}"
    }
    "every_ten_minutes_plus_one" = {
      scheduling_expression = "cron(1/10 * * * ? *)",
      input                 = "{\"foo2\":{\"bar2\": [3,4]}}"
    }
  }
  tags = var.tags
}

# a second example with lambda only and environment agnostic
module "my_second_example_module" {
  source                 = "../" # in this example, this is a local module. For real use, source will be "OpenClassrooms/lambda-apigw-module/aws"
  lambda_project_name    = "second_test"
  lambda_script_name     = "main"
  lambda_handler         = "main"
  lambda_runtime         = "python3.8"
  lambda_code_repo       = "https://github.com/xxx/mysecondrepo"
  lambda_codebase_bucket = aws_s3_bucket.my-lambda-codebase-bucket.bucket
  environment_variables = {
    "no_stage" = {
      MY_SECOND_GREAT_VARIABLE = "test"
    }
  }
}

# a third example with environment agnostic
module "my_third_example_module" {
  source                 = "../" # in this example, this is a local module. For real use, source will be "OpenClassrooms/lambda-apigw-module/aws"
  lambda_project_name    = "second_test"
  lambda_script_name     = "main"
  lambda_handler         = "main"
  lambda_runtime         = "python3.8"
  lambda_code_repo       = "https://github.com/xxx/mysecondrepo"
  lambda_codebase_bucket = aws_s3_bucket.my-lambda-codebase-bucket.bucket
  environment_variables = {
    "no_stage" = {
      MY_THIRD_GREAT_VARIABLE = "test3"
    }
  }
  use_api_gateway                 = true
  api_gateway_domain_name_mapping = var.single_apigw_domain_name_mapping
  api_gateway_path                = "mypath3"
  subnet_ids                      = ["sub-1234", "sub-5678"]
  security_group_ids              = ["sg-1234"]
}
