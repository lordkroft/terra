resource "aws_vpc" "galera-vpc" {
    cidr_block = var.vpc_cidr
  #enable_nat_gateway = true
  #enable_vpn_gateway = true
    tags = {
        Terraform = "true"
        Environment = "${var.environment}-vpc"
     
    }
}

resource "aws_internet_gateway" "galera-igw" {
    vpc_id = aws_vpc.galera-vpc.id
    tags = {
        Name = "${var.environment}-galera-igw"
    }
}

resource "aws_eip" "aws_EIP" {
  vpc   = true
  count = var.private_subnets
  depends_on = [aws_internet_gateway.galera-igw]
#  public_ipv4_pool = "amazon"
}

# resource "aws_subnet" "public_subnet" {
#   vpc_id                  = "${aws_vpc.galera-vpc.id}"
#   cidr_block              = "${element(var.public_subnets_cidr,   count.index)}"
#   count                   = "${length(var.public_subnets_cidr)}"
#   availability_zone       = "${element(var.availability_zones,   count.index)}"
#   map_public_ip_on_launch = true
#   tags = {
#     Name        = "${var.environment}-${element(var.availability_zones, count.index)}-public-subnet"
#     Environment = "${var.environment}"
#   }
# }

data "aws_availability_zones" "available" {}

data "aws_subnet_ids" "public" {
   vpc_id = aws_vpc.galera-vpc.id
   filter {
    name   = "tag:Name"
    values = ["aws_subnet_public*"]
    
  }
}

data "aws_subnet_ids" "private" {
   vpc_id = aws_vpc.galera-vpc.id
   filter {
    name   = "tag:Name"
    values = ["aws_subnet_private*"]
  }
}

resource "aws_subnet" "public_subnets" {
  vpc_id                  = "${aws_vpc.galera-vpc.id}"
  count                   = "${length(data.aws_availability_zones.available.names)}"
  cidr_block              = cidrsubnet("${var.vpc_cidr}", var.newbits_number, count.index)
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.environment}-public-subnets-${count.index + 1}"
    Environment = "${var.environment}"
  }
}

# resource "aws_subnet" "private_subnet" {
#   vpc_id                  = "${aws_vpc.galera-vpc.id}"
#   count                   = "${length(var.private_subnets_cidr)}"
#   cidr_block              = "${element(var.private_subnets_cidr, count.index)}"
#   availability_zone       = "${element(var.availability_zones,   count.index)}"
#   map_public_ip_on_launch = false
#   tags = {
#     Name        = "${var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
#     Environment = "${var.environment}"
#   }
# }

resource "aws_subnet" "private_subnets" {
  vpc_id                  = "${aws_vpc.galera-vpc.id}"
  count                   = "${length(data.aws_availability_zones.available.names)}"
  cidr_block              = cidrsubnet("${var.vpc_cidr}", var.newbits_number, count.index)
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = false
  tags = {
    Name        = "${var.environment}-private-subnets-${count.index + 1}"
    Environment = "${var.environment}"
  }
}

resource "aws_nat_gateway" "galera-nat-gw" {
   count = "${length(data.aws_availability_zones.available.names)}"
   allocation_id     = "${aws_eip.aws_EIP[count.index].id}"
   connectivity_type = "public"
   subnet_id         = "${element(aws_subnet.private_subnets.*.id, 0)}"
   depends_on        = [aws_internet_gateway.galera-igw]
   tags = {
    Name        = "galera-nat-gw"
    Environment = "${var.environment}"
    }
 }

resource "aws_route_table" "galera-private-Rtable" {
    vpc_id = "${aws_vpc.galera-vpc.id}"
    
    tags = {
        Name = "${var.environment}-galera-private-Rtable"
    }
}

resource "aws_route" "private" {
    route_table_id = "${aws_route_table.galera-private-Rtable.id}"
    destination_cidr_block = "0.0.0.0/0" 
    gateway_id = aws_nat_gateway.galera-nat-gw[0]
    }



resource "aws_route_table" "galera-public-Rtable" {
    vpc_id = aws_vpc.galera-vpc.id
    
    tags = {
        Name = "galera-public-Rtable"
        Environment = "${var.environment}"
    }
}

resource "aws_route" "public_nat_gateway" {
    route_table_id = "${aws_route_table.galera-public-Rtable.id}"
    destination_cidr_block = "0.0.0.0/0" 
    gateway_id = "${aws_internet_gateway.galera-igw.id}" 
    }

resource "aws_route_table_association" "public" {
#  count          = "${var.public_subnets_cidr}"
#  count          = "${length(data.aws_availability_zones.available.names)}"
#  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  for_each       =  data.aws_subnet_ids.public.ids
  subnet_id      = each.value
  route_table_id = "${aws_route_table.galera-public-Rtable.id}"
}

resource "aws_route_table_association" "private" {
#  count          = "${var.private_subnets_cidr}"
#  count          = "${length(data.aws_availability_zones.available.names)}"
#  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  for_each       =  data.aws_subnet_ids.private.ids
  subnet_id      = each.value
  route_table_id = "${aws_route_table.galera-private-Rtable.id}"
}
