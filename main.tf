resource "aws_vpc" "test" {

  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "dedicated"

  tags = {
    Name = "TestVPC"
  }
}

resource "aws_subnet" "public" {
    count              = "${length(var.regions)}"
    #name               = "subnet${count.index}" 
    vpc_id             = aws_vpc.test.id
    availability_zone  = "${element(var.regions, count.index)}"
    cidr_block         = "${element(var.cidr_subnets, count.index)}"

    tags = {
        Name = "subnet${count.index}"
    }
}