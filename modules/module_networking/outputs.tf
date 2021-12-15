output "vpc_id" {
    value = aws_vpc.galera_vpc.id
}

output "vpc_cidr" {
    value = aws_vpc.galera_vpc.cidr_block
}

output "aws_igw" {
    value = aws_internet_gateway.galera_igw.id
}

output "aws_nat_gateway" {
    value = aws_nat_gateway.galera_nat_gw[*].id
}

output "public_subnets_ids" {
    value = aws_subnet.public_subnets[*].id
}

output "private_subnets_ids" {
    value = aws_subnet.private_subnets[*].id
}

