terraform {
 backend "s3" {
 encrypt = true
 bucket = "${bucket_name}"
 region = "${var.aws_region}"
 key = /terraform.tfstate
 }
}