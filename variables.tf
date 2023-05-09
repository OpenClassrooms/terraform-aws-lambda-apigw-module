variable "default_tags" {
  type = map(string)
  default = {
    module_github_repo = "https://github.com/OpenClassrooms/terraform-aws-lambda-apigw-module"
  }
}

variable "lambda_project_name" {
  description = "The name of the lambda project"
  default     = "hello"
}

variable "lambda_script_name" {
  description = "The name of the main function invoked (the name of the script actually)"
}

variable "lambda_handler" {
  description = "The function to call in the main script name (usually: main)"
}

variable "lambda_runtime" {
  description = "Runtime to execute on lambda"
  default     = "python3.8"
}

variable "lambda_codebase_bucket_s3_key" {
  description = "The path of the scripts zip"
  default     = "hello.zip"
}

variable "lambda_code_repo" {
  description = "The name of the repository where is stored the lambda code"
}

variable "lambda_memory_size" {
  description = "The memory size given to the function"
  default     = 128
}

variable "lambda_timeout" {
  description = "The time allowed to the function to finish execution"
  default     = 30
}

variable "lambda_cloudwatch_logs_retention" {
  description = "The time in days retention for lambda logs"
  default     = 7
}

variable "api_gateway_cloudwatch_logs_retention" {
  description = "The time in days retention for lambda logs"
  default     = 14
}

variable "api_gateway_http_method" {
  description = "The type of authorization used for the method"
  default     = "ANY"
}

variable "api_gateway_authorization" {
  description = "The type of authorization used for the method"
  default     = "NONE"
}

variable "api_gateway_authorizer_credentials" {
  description = "The authorizer id to be used when the authorization is CUSTOM"
  default     = ""
}

variable "lambda_custom_authorizer_name" {
  description = "The authorizer id to be used when the authorization is CUSTOM"
  default     = ""
}
variable "lambda_custom_authorizer_script_name" {
  description = "The authorizer id to be used when the authorization is CUSTOM"
  default     = ""
}
variable "lambda_custom_authorizer_handler" {
  description = "The authorizer id to be used when the authorization is CUSTOM"
  default     = ""
}

variable "aws_account_id" {
  description = "The AWS Account ID"
  default     = ""
}

variable "aws_region" {
  description = "The AWS region to create the infrastructure in"
  default     = "eu-west-3"
}

variable "tags" {
  description = "The tags to apply"
  type        = map(string)
  default     = {}
}

variable "environment_variables" {
  description = "Environment variables for lambda function"
  default     = {}
  type        = any
}

variable "use_api_gateway" {
  description = "Do you want your lambda function be reachable/callable from api gateway?"
  type        = bool
  default     = false
}

variable "api_gateway_path" {
  description = "The path (without the /) on api gateway which redirect to the lambda function"
  default     = "not_defined"
}

variable "api_gateway_domain_name_mapping" {
  description = "The custom domain name mapping you want your API Gateway respond to"
  type        = map(string)
  default     = {}
}

variable "use_api_gateway_api_key" {
  description = "Set this variable to true if you want your calls to be protected by an api_key"
  type        = bool
  default     = false
}

variable "api_gateway_api_key_list" {
  description = "The api keys list (for more than one client)"
  type        = list(string)
  default     = []
}

variable "api_gateway_stages" {
  description = "The API Gateway stage names"
  type        = list(string)
  default     = ["no_stage"]
}

variable "lambda_codebase_bucket" {
  description = "The s3 bucket where are the code package"
}

variable "apigw_cloudwatch_logs_format" {
  description = "https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html#apigateway-cloudwatch-log-formats"
  default     = "{ \"requestId\":\"$context.requestId\", \"ip\": \"$context.identity.sourceIp\", \"requestTime\":\"$context.requestTime\", \"httpMethod\":\"$context.httpMethod\",\"routeKey\":\"$context.routeKey\", \"status\":\"$context.status\",\"protocol\":\"$context.protocol\", \"responseLength\":\"$context.responseLength\" }"
}

variable "store_api_keys_in_ssm" {
  description = "Set this variable to true if you want your generated api keys in SSM/ParameterStore"
  type        = bool
  default     = false
}

variable "api_keys_prefix_in_ssm" {
  description = "Set this variable override SSM api keys path in SSM/ParameterStore"
  type        = string
  default     = "/vault/aws/apigateway"
}

variable "send_logs_to_newrelic" {
  description = "Do you want your lambda function logs to be sent to a newrelic ingestion lambda function? See: https://docs.newrelic.com/docs/logs/forward-logs/aws-lambda-sending-cloudwatch-logs/"
  type        = bool
  default     = false
}

variable "newrelic_log_ingestion_function_arn" {
  description = "The arn of the Newrelic Lambda function that ingest logs (if send_logs_to_newrelic is enabled)"
  default     = "not_defined"
}

variable "scheduling_enabled" {
  description = "Do you want your lambda function to be launched periodically?"
  type        = bool
  default     = false
}

variable "scheduling_config" {
  description = "The scheduling configuration. Must contain scheduling_expression and input to send to the lambda. See example/main.tf for example implementation"
  default     = {}
  type        = map(any)
}

variable "subnet_ids" {
  description = "The subnet ids you want your lambda to run on"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "The sg ids you want your lambda to run with"
  type        = list(string)
  default     = []
}

variable "sqs_queues_arn" {
  description = "The SQS queues arn"
  type        = list(string)
  default     = []
}

variable "lambda_policy" {
  description = "the additional policy for the lambda"
  type        = string
  default     = ""
}

variable "lambda_policy_enabled" {
  description = "Do you want your lambda function have a policy"
  type        = bool
  default     = false
}

variable "lambda_additional_perms_enabled" {
  description = "Do you want to add additional permissions to your lambda function ?"
  type        = bool
  default     = false
}

variable "lambda_additional_perms" {
  description = "Additional permissions to your lambda function"
  type        = string
  default     = ""
}

variable "api_gateway_validation_schema_enabled" {
  description = "Do you a validation schema for your api?"
  type        = bool
  default     = false
}

variable "api_gateway_validation_schema_content_type" {
  description = "Validation schema content type for the api gateway"
  type        = string
  default     = "application/json"
}

variable "api_gateway_validation_schema" {
  description = "Validation schema for the api gateway"
  type        = string
  default     = ""
}
