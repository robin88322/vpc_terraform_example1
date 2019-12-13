#creating vpc with 3 subnets in different AZ, route table and internet gateway
#

resource "aws_vpc" "test" {

  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "TestVPC"
  }
}

resource "aws_subnet" "test" {
  count                   = "${length(var.regions)}"
  vpc_id                  = "${aws_vpc.test.id}"
  availability_zone       = "${element("${var.regions}", count.index)}"
  cidr_block              = "${var.cidr_subnets["${element("${var.regions}", count.index)}"]}"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet${count.index}"
  }
}
resource "aws_route_table" "test" {
  vpc_id = "${aws_vpc.test.id}"
  tags = {
    Name = "My_route_table"
  }
}

resource "aws_internet_gateway" "test" {
  vpc_id = "${aws_vpc.test.id}"

  tags = {
    Name = "My_internet_gateway"
  }
}

resource "aws_route" "test" {

  route_table_id         = "${aws_route_table.test.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.test.id}"
}

resource "aws_route_table_association" "test" {
  count          = "${length(var.regions)}"
  subnet_id      = "${element(aws_subnet.test.*.id, count.index)}"
  route_table_id = "${aws_route_table.test.id}"
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
    values = ["amzn2-ami-hvm-*"]
  }
  owners = ["amazon"] # Canonical
}

resource "aws_security_group" "test" {
  name   = "allow_80"
  vpc_id = "${aws_vpc.test.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "${var.default_protocol["22"]}"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "${var.default_port}"
    to_port     = "${var.default_port}"
    protocol    = "${var.default_protocol["${var.default_port}"]}"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_80"
  }
}


resource "aws_instance" "test" {
  count           = "${length(var.regions)}"
  ami             = "${data.aws_ami.ec2.id}"
  instance_type   = "t2.micro"
  subnet_id       = "${element("${aws_subnet.test.*.id}", count.index)}"
  security_groups = ["${aws_security_group.test.id}"]
  key_name        = "for_terraform"
  user_data       = <<-EOF
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

  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["${aws_subnet.test.*.id}"]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "test" {
  load_balancer_arn = "${aws_lb.test.arn}"
  port              = "${var.default_port}"
  protocol          = "${var.default_protocol["${var.default_port}"]}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.test.arn}"
  }
}

resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = "${var.default_port}"
  protocol = "${var.default_protocol["${var.default_port}"]}"
  vpc_id   = "${aws_vpc.test.id}"

  lifecycle { create_before_destroy = true }

  health_check {
    protocol = "${var.default_protocol["${var.default_port}"]}"
    port     = "${var.default_port}"
  }
}

resource "aws_lb_target_group_attachment" "test" {
  count            = "${length(var.regions)}"
  target_group_arn = "${aws_lb_target_group.test.arn}"
  target_id        = "${element("${aws_instance.test.*.id}", count.index)}"
  port             = "${var.default_port}"
}