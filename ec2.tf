# Security group for ALB (INTERNET TO ALB)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "SG for ALB"

  vpc_id = aws_vpc.custom.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "sg for ALB"
  }
}

# Security group for EC2 INSTANCES (ALB TO EC2)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "SG for ec2"

  vpc_id = aws_vpc.custom.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "sg ec2"
  }
}


resource "aws_lb" "app_lb" {
  name               = "app-lb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_subnet[*].id
  depends_on         = [aws_internet_gateway.igw_vpc]


}

resource "aws_lb_target_group" "alb_ec2_tg" {

  name     = "web-server-tg"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom.id
  tags = {
    Name = "alb_ec2_target"
  }

}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_ec2_tg.arn
  }
  tags = {
    Name = "alb_ec2_listener"
  }
}

# Launch Template for ec2

resource "aws_launch_template" "ec2_launch_template" {
  name = "web-server"

  image_id      = "ami-047d7c33f6e7b4bc4"
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd.service
              sudo systemctl enable httpd.service
              echo "<h1> Hello world from bambam </h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ec2-web-server"
    }
  }
}





resource "aws_autoscaling_group" "ec2_asg" {
  max_size            = 6
  min_size            = 2
  desired_capacity    = 2
  name                = "web-server-asg"
  target_group_arns   = [aws_lb_target_group.alb_ec2_tg.arn]
  vpc_zone_identifier = aws_subnet.public_subnet[*].id

  launch_template {
    id      = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }

  health_check_type = "EC2"


}

output "alb_dns_name" {
  value = aws_lb.app_lb.dns_name

}

