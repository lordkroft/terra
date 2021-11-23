variable "bucket_name" {
    default = "my-test-musorka"
}

variable "bucket_key" {
    default = "dev/terraform.tfstate"
}

variable "aws_region" {
	default = "us-east-2"
}

# variable "vpc_cidr" {
# 	default = "10.20.0.0/16"
# }


# variable "environment" {
# description = "The environment which to fetch the configuration for."
# type = string
# }

# variable "public_subnets_cidr" {
#     type = list
#     default = ["10.0.101.0/24", "10.0.102.0/24"]
# }

# variable "private_subnets_cidr" {
#     type = list
#     default = ["10.0.1.0/24", "10.0.2.0/24"]
# }

#variable "availability_zones" {
#    type = list
#    default = ["us-east-2a", "us-east-2b"]
#}

# variable "app_count" {
#     default = "1"
# }

# variable "container_image" {
#     default = "galera-app"
# }