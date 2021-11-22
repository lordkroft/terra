variable "vpc_cidr" {
	type = string
}

variable "environment" {
description = "The environment which to fetch the configuration for."
type = string
}

variable "availability_zones" {
    type = list(string)
}

variable public_subnets_cidr {
  type        = number
}

variable private_subnets_cidr {
  type        = number
}

variable newbits_number {
  type        = number
}
