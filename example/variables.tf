variable "aws_region" {
  description = "The AWS region to create the infrastructure in"
  default     = "eu-west-3"
}

variable "tags" {
  type = map(string)
  default = {
    my_tag       = "test"
    a_second_tag = "test"
  }
}

variable "apigw_domain_name_mapping" {
  description = "The custom domain name mapping you want your API Gateway respond to"
  type        = map(string)
  default = {
    staging    = "apigw-staging.mydomain.com"
    production = "apigw.mydomain.com"
  }
}

variable "cloudflare_zone_id" {
  description = "Zone ID in cloudflare to apply the DNS records to. This variable should be defined as an env var like 'export TF_VAR_cloudflare_zone_id=\"xxx\"'"
  type        = string
}


variable "cloudflare_email" {
  description = "Email used to auth on cloudflare. This variable should be defined as an env var like 'export TF_VAR_cloudflare_email=\"xxx\"'"
  type        = string
}

variable "cloudflare_api_key" {
  type    = string
  default = "API Key to auth on Cloudflare. This variable should be defined as an env var like 'export TF_VAR_cloudflare_api_key=\"xxx\"'"
}
