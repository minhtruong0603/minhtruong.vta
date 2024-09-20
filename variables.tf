variable "vpc_name" {
  default = "minhtruong-tf-vpc"
}
variable "cidrvpc" {
  default = "10.0.0.0/16"
}

variable "tags" {
  default = {
    Name  = "minhtruong-tf-vpc"
    Owner = "minhtruong"
  }
}

variable "az_count" {
  default = 3
}