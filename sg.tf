data "aws_subnet_ids" "public" {
   vpc_id = module.aws_vpc.galera-vpc.id.vpc_id
   filter {
    name   = "tag:Name"
    values = ["public_subnet*"]
  }
}

resource "aws_security_group" "galera-alb-sg" {
description = "Controls access to the ALB"
name = "galera-alb-sg"
vpc_id = module.aws_vpc.galera-vpc.id.vpc_id
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 8080
    to_port = 8080
    protocol = "tcp"
}
# ingress {
#     cidr_blocks = [ 
#       "0.0.0.0/0"]
# from_port = 5000
#     to_port = 5000
#     protocol = "tcp"
#   }
// Terraform removes the default rule
egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
tags = {
    Name = "galera-alb-sg"
  }
 }

