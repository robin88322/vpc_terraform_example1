#creating vpc with 3 subnets in different AZ, route table and internet gateway
#
#
#
#
#

resource "aws_vpc" "test" {

  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "TestVPC"
  }
}

resource "aws_subnet" "public" {
    count              = "${length(var.regions)}"
    vpc_id             = aws_vpc.test.id
    availability_zone  = "${element(var.regions, count.index)}"
    cidr_block         = "${element(var.cidr_subnets, count.index)}"
    map_public_ip_on_launch = true

    tags = {
        Name = "subnet${count.index}"
    }
}

resource "aws_route_table" "public"{
    vpc_id = aws_vpc.test.id
    tags = {
        Name = "My_route_table"
    }
}

resource "aws_internet_gateway" "gate"{
    vpc_id = aws_vpc.test.id
    tags = {
        Name = "My_internet_gateway"
    }
}

resource "aws_route" "public_internet_gateway"{

    route_table_id         = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.gate.id
}

resource "aws_route_table_association" "subnet_association"{
    count          = 3
    subnet_id      = element(aws_subnet.public.*.id, count.index)
    route_table_id = aws_route_table.public.id
}

#
#
#
#creating ec2 instance with nlb
#
#
#

data "aws_ami" "ec2" {
  most_recent = true

  filter {
    name   = "name"
    values = [ "amzn2-ami-hvm-*"]
  }
  owners = ["amazon"] # Canonical
}

resource "aws_security_group" "allow_80" {
  name        = "allow_80"
  vpc_id      = aws_vpc.test.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_80"
  }
}


resource "aws_instance" "ins" {
  count           = 3
  ami             = "${data.aws_ami.ec2.id}"
  instance_type   = "t2.micro"
  subnet_id       = element(aws_subnet.public.*.id, count.index)
  security_groups = [aws_security_group.allow_80.id]
  key_name        = "for_terraform"
  user_data = <<-EOF
               #!/bin/bash
               yum update -y
               yum install -y httpd
               echo "Hello, this is server ${count.index} in region ${element(var.regions, count.index)}" > /var/www/html/index.html
               systemctl start httpd
               EOF

  tags = {
    Name = "test${count.index}"
    }
}


resource "aws_lb" "test" {
  count = 3
  name               = "test-lb-tf${count.index}"
  internal           = false
  load_balancer_type = "network"
  subnets            = [element(aws_subnet.public.*.id, count.index)]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "front_end" {
  count = 3
  load_balancer_arn = element(aws_lb.test.*.arn, count.index)
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = element(aws_lb_target_group.test.*.arn, count.index)
  }
}

resource "aws_lb_target_group" "test" {
  count = 3
  name     = "tf-example-lb-tg${count.index}"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.test.id

  lifecycle { create_before_destroy=true }

  health_check {
    #path = "/index.html"
    protocol = "TCP"
    port = 80
  }
}

resource "aws_lb_target_group_attachment" "test" {
  count = 3
  target_group_arn = element(aws_lb_target_group.test.*.arn, count.index)
  target_id        = element(aws_instance.ins.*.id , count.index)
  port             = 80
}