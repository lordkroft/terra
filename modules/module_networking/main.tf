resource "aws_vpc" "galera_vpc" {
    cidr_block = var.vpc_cidr
    tags = {
        Terraform = "true"
        Environment = "${var.environment}_vpc"
     
    }
}

resource "aws_internet_gateway" "galera_igw" {
    vpc_id = aws_vpc.galera_vpc.id
    tags = {
        Name = "${var.environment}_galera_igw"
    }
}

resource "aws_eip" "aws_EIP" {
  vpc   = true
  count = var.private_subnets
  depends_on = [aws_internet_gateway.galera_igw]
#  public_ipv4_pool = "amazon"
}

data "aws_availability_zones" "available" {}



resource "aws_subnet" "public_subnets" {
  vpc_id                  = "${aws_vpc.galera_vpc.id}"
  count                   = var.public_subnets  #"${length(data.aws_availability_zones.available.names)}"
  cidr_block              = cidrsubnet(var.vpc_cidr, var.newbits_number, count.index + 1)
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.environment}_public_subnets_${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_subnets" {
  vpc_id                  = "${aws_vpc.galera_vpc.id}"
  count                   =  var.private_subnets #"${length(data.aws_availability_zones.available.names)}"
  cidr_block              = cidrsubnet(var.vpc_cidr, var.newbits_number, count.index + var.public_subnets + 1)
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = false
  tags = {
    Name        = "${var.environment}_private_subnets-${count.index + 4}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "galera_nat_gw" {
   count = var.private_subnets #"${length(data.aws_availability_zones.available.names)}"
   allocation_id     = "${aws_eip.aws_EIP[count.index].id}"
   subnet_id         = "${element(aws_subnet.public_subnets.*.id, count.index)}"
   depends_on        = [aws_internet_gateway.galera_igw]
   tags = {
    Name        = "galera_nat_gw"
    Environment = var.environment
    }
 }

resource "aws_route_table" "galera_private_Rtable" {
    count = var.private_subnets 
    vpc_id = "${aws_vpc.galera_vpc.id}"
    
    tags = {
        Name = "${var.environment}_galera_private_Rtable"
    }
}

resource "aws_route" "private" {
    count = var.private_subnets
    route_table_id = element(aws_route_table.galera_private_Rtable[*].id, count.index)
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.galera_nat_gw[*].id, count.index)
    }



resource "aws_route_table" "galera_public_Rtable" {
    vpc_id = aws_vpc.galera_vpc.id
    
    tags = {
        Name = "galera_public_Rtable"
        Environment = var.environment
    }
}

resource "aws_route" "public_nat_gateway" {
    route_table_id = "${aws_route_table.galera_public_Rtable.id}"
    destination_cidr_block = "0.0.0.0/0" 
    gateway_id = "${aws_internet_gateway.galera_igw.id}" 
    }

resource "aws_route_table_association" "public" {
  count          = var.public_subnets
#  count          = "${length(data.aws_availability_zones.available.names)}"
#  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
#  for_each       =  toset(data.aws_subnet_ids.public.ids)
  depends_on  =   [aws_subnet.public_subnets,]
  subnet_id      = aws_subnet.public_subnets[count.index].id#each.value
  route_table_id = "${aws_route_table.galera_public_Rtable.id}"
}

resource "aws_route_table_association" "private" {
  count          = var.private_subnets
#  count          = "${length(data.aws_availability_zones.available.names)}"
#  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  #for_each       =  toset(data.aws_subnet_ids.private.ids)
  depends_on  =   [aws_subnet.private_subnets,]
  subnet_id      = aws_subnet.private_subnets[count.index].id #each.value
  route_table_id = "${aws_route_table.galera_private_Rtable[count.index].id}"
}
