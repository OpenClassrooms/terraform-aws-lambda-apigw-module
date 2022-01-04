terraform {
  required_version = "v1.1.2"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "north-virginia"
  region = "us-east-1"
}

# Cloudflare part (for API GW DNS name)
provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}
