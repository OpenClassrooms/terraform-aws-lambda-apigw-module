# AWS API Gateway (REST) Terraform module

Terraform module which provision API Gateway.

## Usage

### API Gateway

```hcl
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

```

## Example

[Complete example](https://github.com/OpenClassrooms/terraform-aws-lambda-apigw-module/blob/master/example/main.tf) - Create API Gateway, lambda, domain name, stage and other resources in various combinations


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.70.0 |
