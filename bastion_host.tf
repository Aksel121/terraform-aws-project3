resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.custom.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["73.227.164.173/32"] # Replace with your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}



variable "instance_type" {
  description = "Bastion host instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for the bastion host"
  type        = string
  default     = "ami-047d7c33f6e7b4bc4" # Update to your region's suitable AMI
}


resource "aws_instance" "bastion_host" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id              = aws_subnet.public_subnet[0].id # Use the first public subnet

  tags = {
    Name = "Bastion Host"
  }
}


output "bastion_host_ip" {
  value = aws_instance.bastion_host.public_ip
}
