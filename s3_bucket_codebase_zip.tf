# create a file in the bucket to avoid lambda creeation fail (the code package must be present)
resource "aws_s3_object" "code_base_package" {
  bucket = var.lambda_codebase_bucket
  key    = var.lambda_codebase_bucket_s3_key
  source = var.lambda_codebase_bucket_s3_key
  # switch to this source for local module testing (path are different if we are in local or remote)
  #source = "../hello.zip"
  lifecycle {
    ignore_changes = all
  }
}
