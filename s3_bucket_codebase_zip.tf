# create a file in the bucket to avoid lambda creeation fail (the code package must be present)
resource "aws_s3_bucket_object" "code_base_package" {
  bucket = var.lambda_codebase_bucket
  key    = "${var.lambda_project_name}.zip"
  source = "hello.zip"
  # switch to this source for local module testing (path are different if we are in local or remote)
  #source = "../hello.zip"
}
