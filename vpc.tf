resource "aws_vpc" "custom" {

  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project-vpc"
  }

}

variable "vpc_availability_zones" {
  type        = list(string)
  description = "avalability zones"
  default     = ["us-west-1a", "us-west-1c"]


}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.custom.id
  count             = length(var.vpc_availability_zones)
  cidr_block        = cidrsubnet(aws_vpc.custom.cidr_block, 8, count.index + 1)
  availability_zone = element(var.vpc_availability_zones, count.index)
  tags = {
    Name = "public subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw_vpc" {
  vpc_id = aws_vpc.custom.id
  tags = {
    Name = "ig"
  }
}

resource "aws_route_table" "custom" {
  vpc_id = aws_vpc.custom.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_vpc.id
  }

  tags = {
    Name = "Public subnet route table"
  }
}


#Association between RT and IG

resource "aws_route_table_association" "PSA" {
  route_table_id = aws_route_table.custom.id
  count          = length(var.vpc_availability_zones)
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
}

resource "aws_eip" "eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw_vpc]

}

# resource "aws_nat_gateway" "ng" {
#  subnet_id = element(aws_subnet.private_subnet[*].id,0)
# allocation_id = aws_eip.eip.id
# depends_on = [ aws_internet_gateway.igw_vpc ]
# tags {
# Name = "NG" }

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}
