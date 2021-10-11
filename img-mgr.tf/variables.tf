variable "region" {
  
}

 variable "ami" {    
  type = string   
  default = "ami-087c17d1fe0178315"
}

variable "instance_type" {    
  type = string
  default = "t2.micro"
}

variable "bucket" {
  default = "matt1069-img-mgr-tf-bucket-23549060345"
}