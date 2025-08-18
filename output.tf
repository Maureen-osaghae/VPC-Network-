output "vpc_resources" {
    value = {
        vpc_id = aws_vpc.demo.id
        vpc_public_ids = aws_subnet.public[*].id
        private_subnet_ids =  aws_subnet.private[*].id
        internet_gateway_id = aws_internet_gateway.demo_igw
        nat_gateway_ids = aws_nat_gateway.private_ngw[*].id

    }
  
}
