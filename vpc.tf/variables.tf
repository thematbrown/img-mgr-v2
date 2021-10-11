variable "region" {
  
}
 variable "main_vpc_cidr" {
    type = string
    default = "10.0.0.0/21"
 }
 variable "public_subnet1" {
    type = string
    default = "10.0.1.0/24"
 }
 variable "private_subnet1" {
    type = string
    default = "10.0.3.0/24"
 }
 variable "public_subnet2" {
    type = string
    default = "10.0.2.0/24"
 }
 variable "private_subnet2" {
    type = string
    default = "10.0.4.0/24"
 }

 variable "az_1" {
   type = string
   default = "us-east-1a"
 }

  variable "az_2" {
   type = string
   default = "us-east-1b"
 }