terraform {
    backend "s3" {}
  }

data "terraform_remote_state" "state" {
    backend = "s3"
    config = {
        bucket = var.bucket_name
        key = var.bucket_key
        region = var.aws_region
    }
}

provider "aws" {
    profile = "lordkroft"
    region =  var.aws_region
}