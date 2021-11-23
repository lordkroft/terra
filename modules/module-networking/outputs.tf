output "vpc_id" {
    value = aws_vpc.main.id
}

output "vpc_cidr" {
    value = aws_vpc.galera-vpc.cidr_block
}

output "aws_igw" {
    value = aws_internet_gateway.galera-igw.id
}

output "aws_nat_gateway" {
    value = aws_nat_gateway.galera-nat-gw[*].id
}

output "public_subnets_ids" {
    value = aws_subnet.public_subnets_cidr[*].id
}

output "private_subnets_ids" {
    value = aws_subnet.private_subnet_cidr[*].id
}

