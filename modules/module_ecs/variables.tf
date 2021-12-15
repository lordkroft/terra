variable "vpc_id" {}


variable "cluster_name" {
  default = "my_ecs_app"
}

variable "private_subnets" {}

variable "public_subnets" {}

variable "desired_count" {
    default = "1"
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

variable "bastion_sg" {}