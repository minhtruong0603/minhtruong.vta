# terraform {
#   required_providers {
#     aws = {
#       source = "hashicorp/aws"
#       version = "5.67.0"
#     }
#     azure = {
#         source = "hashicorp/azurerm"
#         version = "=3.89.0"
#     }

#   }
# }

# provider "aws" {
#   # Configuration options
#   # version = "~> 3.0"
#   profile = "default"
#   region = "ap-southeast-2"
# }



# # provision the vm
# resource "aws_instance" "this" {
#     ami = "ami-04a5ce820a419d6da"
#     instance_type = "t2.micro"
#     key_name = "mtruong-ssh-key"
#     security_groups = [ "sg-0d69bf77c297a4cca" ]
#     subnet_id = "subnet-0ecc896d08febddd5"
#     tags = {
#         Name = "HelloWorld"
#         CreatedBy = "mtruong"
#     }
# }


#create the vpc
resource "aws_vpc" "minhtruong-vpc" {
  cidr_block = var.cidrvpc
  tags = var.tags
}

resource "aws_subnet" "public" {

  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.minhtruong-vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.minhtruong-vpc.id
  tags = merge({
    Name = "${var.vpc_name}-public-subnet"
    },var.tags)
}

resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.minhtruong-vpc.id
  tags = merge({
    Name = "${var.vpc_name}-igw"
    },
  var.tags)
}

resource "aws_route" "main-route" {
  route_table_id         = aws_vpc.minhtruong-vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main-igw.id
}

resource "aws_route_table_association" "public-subnet-rtb" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_vpc.minhtruong-vpc.main_route_table_id
}

resource "aws_subnet" "private" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.minhtruong-vpc.cidr_block, 8, count.index + var.az_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.minhtruong-vpc.id
  tags = merge({
    Name = "${var.vpc_name}-private-subnet"
    }, var.tags)
}

resource "aws_eip" "ngweip" {
  count = var.az_count
  tags = merge({
    Name = "${var.vpc_name}-ngw-eip-${count.index}"
    }, var.tags)
}
resource "aws_nat_gateway" "ngw" {
  count         = var.az_count
  subnet_id     = element(aws_subnet.private.*.id, count.index)
  allocation_id = element(aws_eip.ngweip.*.id, count.index)
  tags = merge({ 
    Name = "${var.vpc_name}-ngw-eip-${count.index}" 
    }, var.tags)
}

resource "aws_route_table" "private_rtb" {
  count  = var.az_count
  vpc_id = aws_vpc.minhtruong-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.ngw.*.id, count.index)
  }
  tags = merge({
    ext-name = "${var.vpc_name}-private-rtb-${count.index}"
    }, var.tags)
}

resource "aws_route_table_association" "private-subnet-rtb" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private_rtb.*.id, count.index)
}