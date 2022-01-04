# create a file in the bucket to avoid lambda creeation fail (the code package must be present)
resource "aws_s3_bucket_object" "code_base_package" {
  bucket = var.lambda_codebase_bucket
  key    = "${var.lambda_project_name}.zip"
  #source = "hello.zip"
  source = "../hello.zip"
}
