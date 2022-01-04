output "api_urls_curls" {
  description = "Curl commands to reach the api"
  value = toset([
    for k, rec in cloudflare_record.api-gw : "curl -H x-api-key:XXXXX https://${rec.name}/${module.my_example_module.api_path}"
  ])
}
