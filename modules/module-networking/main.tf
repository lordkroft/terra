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

data "aws_availability_zones" "available" {}

# data "aws_subnet_ids" "public" {
#    vpc_id = aws_vpc.galera-vpc.id
#    filter {
#     name   = "tag:Name"
#     values = ["aws_subnet_public*"]
    
#   }
# }

# data "aws_subnet_ids" "private" {
#    vpc_id = aws_vpc.galera-vpc.id
#     filter {
#     name   = "tag:Name"
#     values = ["aws_subnet_private*"]
#   }
# }

resource "aws_subnet" "public_subnets" {
  vpc_id                  = "${aws_vpc.galera-vpc.id}"
  count                   = var.public_subnets  #"${length(data.aws_availability_zones.available.names)}"
  cidr_block              = cidrsubnet("${var.vpc_cidr}", var.newbits_number, count.index + 1)
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.environment}-public-subnets-${count.index + 1}"
    Environment = "${var.environment}"
  }
}

resource "aws_subnet" "private_subnets" {
  vpc_id                  = "${aws_vpc.galera-vpc.id}"
  count                   =  var.private_subnets #"${length(data.aws_availability_zones.available.names)}"
  cidr_block              = cidrsubnet("${var.vpc_cidr}", var.newbits_number, count.index + var.public_subnets + 1)
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = false
  tags = {
    Name        = "${var.environment}-private-subnets-${count.index + 4}"
    Environment = "${var.environment}"
  }
}

resource "aws_nat_gateway" "galera-nat-gw" {
   count = var.private_subnets #"${length(data.aws_availability_zones.available.names)}"
   allocation_id     = "${aws_eip.aws_EIP[count.index].id}"
   connectivity_type = "public"
   subnet_id         = "${element(aws_subnet.private_subnets.*.id, count.index)}"#0
   depends_on        = [aws_internet_gateway.galera-igw]
   tags = {
    Name        = "galera-nat-gw"
    Environment = "${var.environment}"
    }
 }

resource "aws_route_table" "galera-private-Rtable" {
    count = var.private_subnets # 2 подсети
    vpc_id = "${aws_vpc.galera-vpc.id}"
    
    tags = {
        Name = "${var.environment}-galera-private-Rtable"
    }
}

resource "aws_route" "private" {
    count = var.private_subnets
    route_table_id = element(aws_route_table.galera-private-Rtable[*].id, count.index)
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.galera-nat-gw[*].id, count.index)
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
  count          = "${var.public_subnets}"
#  count          = "${length(data.aws_availability_zones.available.names)}"
#  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
#  for_each       =  toset(data.aws_subnet_ids.public.ids)
  depends_on  =   [aws_subnet.public_subnets,]
  subnet_id      = aws_subnet.public_subnets[count.index].id#each.value
  route_table_id = "${aws_route_table.galera-public-Rtable.id}"
}

resource "aws_route_table_association" "private" {
  count          = "${var.private_subnets}"
#  count          = "${length(data.aws_availability_zones.available.names)}"
#  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  #for_each       =  toset(data.aws_subnet_ids.private.ids)
  depends_on  =   [aws_subnet.private_subnets,]
  subnet_id      = aws_subnet.private_subnets[count.index].id #each.value
  route_table_id = "${aws_route_table.galera-private-Rtable[count.index].id}"
}
