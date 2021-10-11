output "vpc_id" {
  description = "ID of project VPC"
  value = aws_vpc.Main.id
}

output "public_subnets" {
  description = "List of public subnets"
  value = [ aws_subnet.publicsubnet1.id, aws_subnet.publicsubnet2.id ]
}

output "private_subnets" {
  description = "List of private subnets"
  value = [ aws_subnet.privatesubnet1.id, aws_subnet.privatesubnet2.id ]
}