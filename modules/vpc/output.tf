output "vpc_id" {
  value = aws_vpc.vpc.id

}

output "public_subnet_ids" {

  description = "IDs of the public subnets"
  value       = aws_subnet.public_subnet[*].id

}

output "private_subnet_ids" {
  description = "IDs of the public subnet"
  value       = aws_subnet.public_subnet[*].id

}