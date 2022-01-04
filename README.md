# AWS API Gateway (REST) Terraform module

Terraform module which provision API Gateway.

## Usage

### API Gateway

```hcl
module "my_example_module" {
  source                           = "OpenClassrooms/lambda-apigw-module/aws"
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
  api_gateway_domain_name_mapping       = var.apigw_domain_name_mapping
  api_gateway_path                      = "mypath"
  api_gateway_stages                    = ["production", "staging"]
  api_gateway_cloudwatch_logs_retention = 7
  tags                                  = var.tags
}

```

## Example

[Complete example](https://github.com/OpenClassrooms/terraform-aws-lambda-apigw-module/blob/master/example/main.tf) - Create API Gateway, lambda, domain name, stage and other resources in various combinations


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.70.0 |
