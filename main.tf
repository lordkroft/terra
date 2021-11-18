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

resource "aws_vpc" "galera-vpc" {
    cidr_block = var.vpc_cidr
  #enable_nat_gateway = true
  #enable_vpn_gateway = true
    tags = {
        Terraform = "true"
        Environment = "${var.environment}"
     
    }
}

resource "aws_internet_gateway" "galera-igw" {
    vpc_id = aws_vpc.galera-vpc.id
    tags = {
        Name = "galera-igw"
    }
}

resource "aws_eip" "nat_EIP" {
  vpc   = true
  depends_on = [aws_internet_gateway.galera-igw]
#  public_ipv4_pool = "amazon"
}

resource "aws_nat_gateway" "galera-NATgw" {
   allocation_id = aws_eip.nat_EIP.id
   subnet_id = "${element(aws_subnet.public_subnet.*.id, 0)}"
   depends_on    = [aws_internet_gateway.galera-igw]
   tags = {
    Name        = "nat"
    Environment = "${var.environment}"
    }
 }

resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.galera-vpc.id}"
  count                   = "${length(var.public_subnets_cidr)}"
  cidr_block              = "${element(var.public_subnets_cidr,   count.index)}"
  availability_zone       = "${element(var.availability_zones,   count.index)}"
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-public-subnet"
    Environment = "${var.environment}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = "${aws_vpc.galera-vpc.id}"
  count                   = "${length(var.private_subnets_cidr)}"
  cidr_block              = "${element(var.private_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.availability_zones,   count.index)}"
  map_public_ip_on_launch = false
  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table" "galera-private-Rtable" {
    vpc_id = "${aws_vpc.galera-vpc.id}"
    
    tags = {
        Name = "${var.environment}-galera-private-Rtable"
    }
}

resource "aws_route" "private_internet_gateway" {
    route_table_id = "${aws_route_table.galera-private-Rtable.id}"
    destination_cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.galera-igw.id
    }



resource "aws_route_table" "galera-public-Rtable" {
    vpc_id = aws_vpc.galera-vpc.id
    
    tags = {
        Name = "galera-public-Rtable"
        Environment = "${var.environment}-galera-public-Rtable"
    }
}

resource "aws_route" "public_nat_gateway" {
    route_table_id = "${aws_route_table.galera-public-Rtable.id}"
    destination_cidr_block = "0.0.0.0/0" 
    gateway_id = "${aws_nat_gateway.galera-NATgw.id}" 
    }

resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.galera-public-Rtable.id}"
}
resource "aws_route_table_association" "private" {
  count          = "${length(var.private_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.galera-private-Rtable.id}"
}

resource "aws_security_group" "galera-bastion-ssh" {
  depends_on=[aws_subnet.public_subnet]
name        = "only_ssh_bositon"
vpc_id = "${aws_vpc.galera-vpc.id}"
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 22
    to_port = 22
    protocol = "tcp"
  }
// Terraform removes the default rule
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
tags = {
  Name = "only_ssh_bositon"
  }
}

resource "aws_security_group" "galera-jenkins" {
name        = "jenkins-sg"
vpc_id = "${aws_vpc.galera-vpc.id}"
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 22
    to_port = 22
    protocol = "tcp"
}
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 8080
    to_port = 8080
    protocol = "tcp"
  }
// Terraform removes the default rule
egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
tags = {
    Name = "jenkins-sg"
  }
 }


resource "aws_security_group" "galera-alb-sg" {
name = "galera-alb-sg"
vpc_id = "${aws_vpc.galera-vpc.id}"
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 8080
    to_port = 8080
    protocol = "tcp"
}
ingress {
    cidr_blocks = [
      "0.0.0.0/0"]
from_port = 5000
    to_port = 5000
    protocol = "tcp"
  }
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


resource "aws_security_group" "galera-http-sg" {
name = "galera-http-sg"
vpc_id = "${aws_vpc.galera-vpc.id}"
ingress {
    # cidr_blocks = [
    #   "0.0.0.0/0"
    # ]
from_port = 5000
    to_port = 5000
    protocol = "tcp"
    security_groups = [aws_security_group.galera-alb-sg.id]
  }
// Terraform removes the default rule
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
tags = {
    Name = "galera-http-sg"
  }
}

resource "aws_ecr_repository" "galera-ecr" {
  name                 = "galera-ecr"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "galera-ecr-policy" {
  repository = aws_ecr_repository.galera-ecr.name
 
  policy = jsonencode({
   rules = [{
     rulePriority = 1
     description  = "keep last 5 images"
     action       = {
       type = "expire"
     }
     selection     = {
       tagStatus   = "any"
       countType   = "imageCountMoreThan"
       countNumber = 5
     }
   }]
  })
}

resource "aws_lb" "galera-lb" {
  name            = "galera-lb"
  subnets         = aws_subnet.public_subnet.*.id
  security_groups = [aws_security_group.galera-alb-sg.id]
}


resource "aws_lb_target_group" "galera-tg-http" {
  name        = "galera-tg-http"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.galera-vpc.id
  target_type = "ip"
}


resource "aws_lb_listener" "galera-http-listener" {
  load_balancer_arn = aws_lb.galera-lb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.galera-tg-http.id
    type             = "forward"
  }
}

resource "aws_iam_role" "galera-ecs-task-role" {
  name = "galera-ecsTaskRole"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_ecs_task_definition" "galera-app" {
  family                   = "galera-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = "arn:aws:iam::413752907951:user/lordkroft" #aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.galera-ecs-task-role.id
  container_definitions = jsonencode([{
   name        = "galera-app"
   image       = "${var.container_image}:latest"
   essential   = true
   #environment = var.container_environment
   portMappings = [{
     protocol      = "tcp"
     containerPort = 5000
     hostPort      = 5000
  }]
  }])
  }

resource "aws_ecs_cluster" "galera-cluster" {
  name = "galera-cluster"
}

resource "aws_ecs_service" "galera-app-service" {
  name            = "galera-app-service"
  cluster         = aws_ecs_cluster.galera-cluster.id
  task_definition = aws_ecs_task_definition.galera-app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.galera-http-sg.id]
    subnets         = aws_subnet.private_subnet.*.id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.galera-tg-http.id
    container_name   = "galera-app"
    container_port   = 5000
  }
  depends_on = [aws_lb_listener.galera-http-listener]
} 

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.galera-cluster.name}/${aws_ecs_service.galera-app-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
 
  target_tracking_scaling_policy_configuration {
   predefined_metric_specification {
     predefined_metric_type = "ECSServiceAverageMemoryUtilization"
   }
 
   target_value       = 90
   
  }
}
 
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
 
  target_tracking_scaling_policy_configuration {
   predefined_metric_specification {
     predefined_metric_type = "ECSServiceAverageCPUUtilization"
   }
 
   target_value       = 80
  }
}

# resource "aws_instance" "jenki" {
#   ami           = "ami-0ba62214afa52bec7"
#   instance_type = "t3.medium"

#     key_name               = "app-demo-key"
#     monitoring             = true
#     vpc_security_group_ids = aws_security_group.galera-jenkins.id
#     subnet_id              = aws_subnet.public_subnet.id
  
#   tags = {
#     Name = "jenki"
#   }
# }

# resource "aws_instance" "bastion" {
#   ami           = "ami-0629230e074c580f2"
#   instance_type = "t2.micro"
#   subnet_id = aws_subnet.public_subnet.id
#   vpc_security_group_ids = [ aws_security_group.galera-bastion-ssh.id ]
#   key_name = "app-demo-key"

#   tags = {
#     Name = "bastion"
#     }
# }
