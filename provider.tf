provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"

  version = "~> 2.7"
}

terraform {
 backend "s3" {
 encrypt = true
 bucket = "my.tfstate.bucket"
 region = "us-east-2"
 key = "terraform.tfstate"
 }
}