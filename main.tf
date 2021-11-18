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



#module "vpc" {
#    source = "terraform-aws-modules/vpc/aws"
#    version = "2.21.0"
#    name = "galera-vpc"
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

# resource "aws_subnet" "galera-subnet-public-1" {
#     vpc_id = aws_vpc.galera-vpc.id
#     cidr_block = "10.0.101.0/24"
#     map_public_ip_on_launch = "true" //it makes this a public subnet
#     availability_zone = "us-east-2a"
#     tags = {
#         Name = "galera-subnet-public-1"
#     }
# }
# resource "aws_subnet" "galera-subnet-public-2" {
#     vpc_id = aws_vpc.galera-vpc.id
#     cidr_block = "10.0.102.0/24"
#     map_public_ip_on_launch = "true" //it makes this a public subnet
#     availability_zone = "us-east-2b"
#     tags = {
#         Name = "galera-subnet-public-2"
#     }
# }

# resource "aws_subnet" "galera-subnet-private-1" {
#     vpc_id = aws_vpc.galera-vpc.id
#     cidr_block = "10.0.1.0/24"
#     map_public_ip_on_launch = "true" //it makes this a public subnet
#     availability_zone = "us-east-2a"
#     tags = {
#         Name = "galera-subnet-private-1"
#     }
# }

# resource "aws_subnet" "galera-subnet-private-2" {
#     vpc_id = aws_vpc.galera-vpc.id
#     cidr_block = "10.0.2.0/24"
#     map_public_ip_on_launch = "true" //it makes this a public subnet
#     availability_zone = "us-east-2b"
#     tags = {
#         Name = "galera-subnet-private-2"
#     }
# }
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

# #Route table Association with Public Subnet's
#  resource "aws_route_table_association" "PublicRTassociation" {
#     subnet_id = aws_subnet.galera-subnet-public-1.id
#     route_table_id = aws_route_table.galera-public-Rtable.id
#  }
# # Route table Association with Private Subnet's
#  resource "aws_route_table_association" "PrivateRTassociation" {
#     subnet_id = aws_subnet.galera-subnet-private-1.id
#     route_table_id = aws_route_table.galera-private-Rtable.id
#  }

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

resource "aws_security_group" "galera-alb" {
name = "alb-sg"
vpc_id = "${aws_vpc.galera-vpc.id}"
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 8080
    to_port = 8080
    protocol = "tcp"
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
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
    Name = "alb-sg"
  }
}

resource "aws_security_group" "galera-app" {
name = "allow-http-sg"
vpc_id = "${aws_vpc.galera-vpc.id}"
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 80
    to_port = 80
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
    Name = "allow_http-sg"
  }
}




# resource "aws_instance" "jenki" {
#   ami           = "ami-0ba62214afa52bec7"
#   instance_type = "t3.medium"

#   tags = {
#     Name = "jenki"
#   }
#     key_name               = "app-demo-key"
#     monitoring             = true
#     vpc_security_group_ids = ["sg-09418841b953f534c"]
#     subnet_id              = "subnet-0388b7335b4f4c6e2"
  
# }

# resource "aws_instance" "BASTION" {
#   ami           = "ami-0732b62d310b80e97"
#   instance_type = "t2.micro"
#   subnet_id = aws_subnet.My_VPC_Subnet.id
#   vpc_security_group_ids = [ aws_security_group.only_ssh_bositon.id ]
#   key_name = "task1-key"

#   tags = {
#     Name = "bastionhost"
#     }
# }



