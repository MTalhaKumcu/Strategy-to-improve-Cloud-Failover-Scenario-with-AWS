resource "aws_security_group" "alb_sec_gr" {
  name        = "${var.tag_name}-ALB-sec-gr"
  description = "ALB Security Group allows traffic HTTP and HTTPS ports from anywhere"
  vpc_id      = aws_vpc.main_vpc.id



  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      description = "HTTP/HTTPS inbound traffic"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

      ipv6_cidr_blocks = ["::/0"]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name  = "${var.tag_name}-ALB-sec-gr"
    Owner = "${var.tag_owner}"
  }
}

resource "aws_security_group" "ec2_sec_gr" {
  name        = "${var.tag_name}-ec2-sec-gr"
  description = "EC2 Security Group only allows traffic coming from ALB Security Group for HTTP, HTTPS and SSH port from anywhere "
  vpc_id      = aws_vpc.main_vpc.id



  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      description     = "HTTP/HTTPS inbound traffic"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.alb_sec_gr.id]
    }
  }

  ingress {
    description      = "SSH inbound traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name  = "${var.tag_name}-ec2-sec-gr"
    Owner = "${var.tag_owner}"
  }
}

resource "aws_security_group" "rds_sec_gr" {
  name        = "${var.tag_name}-RDS-sec-gr"
  description = "RDS Security Group only allows traffic coming from EC2 Security Group for MYSQL/Aurora port"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description     = "MYSQL/Aurora inbound traffic"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sec_gr.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name  = "${var.tag_name}-RDS-sec-gr"
    Owner = "${var.tag_owner}"
  }
}

resource "aws_security_group" "nat_instance_sec_gr" {
  name        = "${var.tag_name}-NAT-instance-sec-gr"
  description = "NAT Instance Security Group allows traffic HTTP, HTTPS and SSH ports from anywhere"
  vpc_id      = aws_vpc.main_vpc.id

  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      description      = "HTTP/HTTPS inbound traffic"
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  ingress {
    description      = "SSH inbound traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name  = "${var.tag_name}-NAT-instance-sec-gr"
    Owner = "${var.tag_owner}"
  }
}

resource "aws_security_group" "bastion_host_sec_gr" {
  name        = "${var.tag_name}-bastion-host-sec-gr"
  description = "Bastion Host Security Group allows SSH port from anywhere "
  vpc_id      = aws_vpc.main_vpc.id


  ingress {
    description      = "SSH inbound traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name  = "${var.tag_name}-bastion-host-sec-gr"
    Owner = "${var.tag_owner}"
  }
}
