variable "bucket_name" {
  default = "my-test-musorka"
}

variable "bucket_key" {
  default = "dev/terraform.tfstate"
}

variable "aws_region" {
  default = "us-east-2"
}

variable "vpc_id" {
  default = "galera_vpc"
}


variable "environment" {
  description = "The environment which to fetch the configuration for."
  type        = string
}




