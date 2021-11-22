terraform {
    backend "s3" {
        bucket = "my-test-musorka"
        key = "dev/terraform.tfstate"
        region = "us-east-2"
    }
}

provider "aws" {
    profile = "lordkroft"
    region = "us-east-2"
}