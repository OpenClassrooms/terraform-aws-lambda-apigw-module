variable "default_tags" {
  type = map(string)
  default = {
    deployed_by        = "terraform"
    stack              = "infra"
    module_github_repo = "https://github.com/OpenClassrooms/terraform-aws-lambda-apigw-module"
  }
}
variable "lambda_project_name" {
  description = "The name of the lambda project"
}
variable "lambda_script_name" {
  description = "The name of the main function invoked (the name of the script actually)"
}
variable "lambda_handler" {
  description = "The function to call in the main script name (usually: main)"
}
variable "lambda_runtime" {
  description = "Runtime to execute on lambda"
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

variable "tags" {
  description = "The tags to apply"
  type        = map(string)
  default     = {}
}

variable "environment_variables" {
  description = "Environment variables for lambda function"
  default     = {}
  type        = map(any)
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

variable "api_gateway_api_key" {
  description = "Set this variable to true if you want your calls to be protected by an api_key"
  type        = bool
  default     = false
}

variable "api_gateway_stages" {
  description = "The API Gateway stage names"
  type        = list(string)
  default     = ["production"]
}

variable "lambda_codebase_bucket" {
  description = "The s3 bucket where are the code package"
}

variable "api_gateway_custom_domain" {
  description = "The custom domain name map to the rest api"
}

variable "apigw_cloudwatch_logs_format" {
  description = "https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html#apigateway-cloudwatch-log-formats"
  default     = "{ \"requestId\":\"$context.requestId\", \"ip\": \"$context.identity.sourceIp\", \"requestTime\":\"$context.requestTime\", \"httpMethod\":\"$context.httpMethod\",\"routeKey\":\"$context.routeKey\", \"status\":\"$context.status\",\"protocol\":\"$context.protocol\", \"responseLength\":\"$context.responseLength\" }"
}
