variable "vpc_cidr" {
	type = string
}

variable "environment" {
description = "The environment which to fetch the configuration for."
type = string
}

# variable "availability_zones" {
#     type = list(string)
# }

variable public_subnets {
  type        = number
}

variable private_subnets {
  type        = number
}

variable newbits_number {
  type        = number
}
