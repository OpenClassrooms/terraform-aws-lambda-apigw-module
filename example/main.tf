# Prerequisite before using the module
resource "aws_s3_bucket" "my-lambda-codebase-bucket" {
  bucket = "my-test-lambda-codebase-bucket"
  acl    = "private"

  tags = var.tags
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
  tags                                  = var.tags
}
