terraform {
 backend "s3" {
 encrypt = true
 bucket = "my.tfstate.bucket"
 region = "us-east-2"
 key = "terraform.tfstate"
 }
}