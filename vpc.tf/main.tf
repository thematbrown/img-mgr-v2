# Backend setup
terraform {
  backend "s3" {
    key = "vpc.tfstate"
  }
}

# Provider and access setup
provider "aws" {
  version = ">= 3.62.0"
  region = "${var.region}"
}


 resource "aws_vpc" "Main" {                # Creating VPC here
   cidr_block       = var.main_vpc_cidr     # Defining the CIDR block use 10.0.0.0/24 for demo
   instance_tenancy = "default"
   tags = {
        Name = "tf-vpc"
  }
 }
 
 resource "aws_internet_gateway" "IGW" {    # Creating Internet Gateway
    vpc_id =  aws_vpc.Main.id               # vpc_id will be generated after we create VPC
    tags = {
        Name = "tf-igw"
  }
 }
 
 resource "aws_subnet" "publicsubnet1" {    # Creating Public Subnets
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.public_subnet1}"        # CIDR block of public subnets
   availability_zone = "${var.az_1}"
   tags = {
        Name = "public-subnet-1"
  }
 }

 resource "aws_subnet" "publicsubnet2" {    # Creating Public Subnets
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.public_subnet2}"        # CIDR block of public subnets
   availability_zone = "${var.az_2}"
   tags = {
        Name = "public-subnet-2"
  }
 }
                                                 # Creating Private Subnets
 resource "aws_subnet" "privatesubnet1" {
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.private_subnet1}"          # CIDR block of private subnets
   availability_zone = "${var.az_1}"
   tags = {
        Name = "private-subnet-1"
  }
 }
 
 resource "aws_subnet" "privatesubnet2" {
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.private_subnet2}"          # CIDR block of private subnets
   availability_zone = "${var.az_2}"
   tags = {
        Name = "private-subnet-2"
  }
 }
 resource "aws_route_table" "PublicRT" {    # Creating RT for Public Subnet
    vpc_id =  aws_vpc.Main.id
         route {
    cidr_block = "0.0.0.0/0"               # Traffic from Public Subnet reaches Internet via Internet Gateway
    gateway_id = aws_internet_gateway.IGW.id
     }
    tags = {
        Name = "public-route-table"
  }
 }
 
 resource "aws_route_table" "PrivateRT" {    # Creating RT for Private Subnet
   vpc_id = aws_vpc.Main.id
   route {
   cidr_block = "0.0.0.0/0"             # Traffic from Private Subnet reaches Internet via NAT Gateway
   nat_gateway_id = aws_nat_gateway.NATgw.id
   }
   tags = {
        Name = "private-route-table-1"
  }
 }

 resource "aws_route_table" "PrivateRT2" {    # Creating RT for Private Subnet
   vpc_id = aws_vpc.Main.id
   route {
   cidr_block = "0.0.0.0/0"             # Traffic from Private Subnet reaches Internet via NAT Gateway
   nat_gateway_id = aws_nat_gateway.NATgw2.id
   }
   tags = {
        Name = "private-route-table-2"
  }
 }
 
 resource "aws_route_table_association" "PublicRTassociation1" {
    subnet_id = aws_subnet.publicsubnet1.id
    route_table_id = aws_route_table.PublicRT.id
 }

 resource "aws_route_table_association" "PublicRTassociation2" {
    subnet_id = aws_subnet.publicsubnet2.id
    route_table_id = aws_route_table.PublicRT.id
 }
 
 resource "aws_route_table_association" "PrivateRTassociation1" {
    subnet_id = aws_subnet.privatesubnet1.id
    route_table_id = aws_route_table.PrivateRT.id
 }

  resource "aws_route_table_association" "PrivateRTassociation2" {
    subnet_id = aws_subnet.privatesubnet2.id
    route_table_id = aws_route_table.PrivateRT2.id
 }
 resource "aws_eip" "nateIP" {
   vpc   = true
 }

 resource "aws_eip" "nateIP2" {
   vpc   = true
 }
 
 resource "aws_nat_gateway" "NATgw" {
   allocation_id = aws_eip.nateIP.id
   subnet_id = aws_subnet.publicsubnet1.id
   tags = {
        Name = "nat-gw-1"
  }
 }

 resource "aws_nat_gateway" "NATgw2" {
   allocation_id = aws_eip.nateIP2.id
   subnet_id = aws_subnet.publicsubnet2.id
   tags = {
        Name = "nat-gw-2"
  }
 }
