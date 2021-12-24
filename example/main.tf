# Prerequisite before using the module
resource "aws_s3_bucket" "my-lambda-codebase-bucket" {
  bucket = "my-test-lambda-codebase-bucket"
  acl    = "private"

  tags = var.tags
}

# Not mandatory, but useful

# First, we declare a pretty domain name for the API Gateway
resource "aws_apigatewayv2_domain_name" "apigw_domain_name_name" {
  domain_name = var.apigw_domain_name
  domain_name_configuration {
    certificate_arn = aws_acm_certificate.apigw_certificate.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
  tags = var.tags
}

# Then, we need a DNS name for the api gateway
resource "cloudflare_record" "api-gw" {
  zone_id = var.cloudflare_zone_id
  name    = var.apigw_domain_name
  value   = aws_apigatewayv2_domain_name.apigw_domain_name_name.domain_name_configuration[0].target_domain_name
  type    = "CNAME"
  ttl     = 1
  proxied = false
}


# Next need a TLS Certificate for our API Gateway custom domain
resource "aws_acm_certificate" "apigw_certificate" {
  ## Cert must be in us-east-1 for API-GW custom domain: https://aws.amazon.com/premiumsupport/knowledge-center/custom-domain-name-amazon-api-gateway/?nc1=h_ls
  #provider          = aws.north-virginia
  domain_name       = var.apigw_domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}

# Fianlly a DNS record for the certificate validation
resource "cloudflare_record" "api-gw-cert-validation" {
  # Little trick to get domain_validation_options attributes
  for_each = {
    for dvo in aws_acm_certificate.apigw_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  value   = each.value.record
  type    = each.value.type
  ttl     = 1
  proxied = false
}



module "my_example_module" {
  source                           = "../" # in this example, this is a local module. For real use, source will be "OpenClassrooms/lambda-apigw-module/aws"
  lambda_project_name              = "test"
  lambda_script_name               = "my_main_script"
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
  api_gateway_api_key                   = true
  api_gateway_custom_domain             = var.apigw_domain_name
  api_gateway_path                      = "/mypath"
  api_gateway_stages                    = ["production", "staging"]
  api_gateway_cloudwatch_logs_retention = 7
  tags                                  = var.tags
}
