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
 	default = "galera-vpc"
 }


variable "environment" {
description = "The environment which to fetch the configuration for."
type = string
}

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

variable "desired_count" {
    default = "1"
}

variable "container_image_front" {
    default = "413752907951.dkr.ecr.us-east-2.amazonaws.com/frontend"
}

variable "container_image_back" {
    default = "413752907951.dkr.ecr.us-east-2.amazonaws.com/backend"
}

variable "deployment_maximum_percent" {
    default = "200"
}

variable "deployment_minimum_healthy_percent" {
    default = "50"
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 1800. Only valid for services configured to use load balancers."
  default     = 0
}
