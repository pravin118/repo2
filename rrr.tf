variable "vpc_cidr"{
type = string
default = "10.0.0.0/16"
}
variable "pubsn_cidrs"{
type = list
default = ["10.0.0.0/24" , "10.0.1.0/24" ,"10.0.2.0/24" ]
}
variable "pvtsn_cidrs"{
type = list
default = ["10.0.3.0/24" , "10.0.4.0/24" ,"10.0.5.0/24" ]
}
 variable "azs"{
 type = list
 default = ["ap-southeast-1a" , "ap-southeast-1b" , "ap-southeast-1c" ]
 }
 variable "tags"{
 type = list
default = ["sn11" ,"sn22" , "sn33"]
}
  variable "pvttags"{
 type = list
default = ["sn44" ,"sn55" , "sn66"]
}
resource "aws_vpc" "vpc1" {
  cidr_block       = var.vpc_cidr

  tags = {
    Name = "vpc1"
  }
}
resource "aws_subnet" "pubsub" {
count = length(var.pubsn_cidrs)
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = var.pubsn_cidrs[count.index]
  availability_zone =var.azs[count.index]

  tags = {
    Name =var.tags[count.index]
  }
}
resource "aws_subnet" "pvtsub" {
count = length(var.pvtsn_cidrs)
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = var.pvtsn_cidrs[count.index]
  availability_zone =var.azs[count.index]

  tags = {
    Name =var.pvttags[count.index]
  }
}
resource "aws_internet_gateway" "gw1" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "gw1"
  }
}
variable "igw_cidr"{
type = string
default = "0.0.0.0/0"
}
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = var.igw_cidr
    gateway_id = aws_internet_gateway.gw1.id
  }
  tags = {
    Name = "rt1"
  }
}

resource "aws_route_table_association" "a1" {
       count = length(var.pubsn_cidrs) 
  subnet_id      = aws_subnet.pubsub.*.id[count.index]
  route_table_id = aws_route_table.rt1.id
}
variable "targetgroupes"{
default = ["prepaidtg" , "postpaidtg"]
}
variable "tgports"{
type = map
default ={
prepaidtg ="80"
postpaidtg = "90"
}
}


resource "aws_lb_target_group" "targetgroups" {
count = length(var.targetgroupes)
  name     = var.targetgroupes[count.index]
  port     = var.tgports[var.targetgroupes[count.index]]
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc1.id
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.aelb.id]
  subnets            = ["${aws_subnet.pubsub.*.id}"]
}