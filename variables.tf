variable "aws_region" {
  default = "us-east-2"
}

variable "regions"{
    type = "list"
    default = ["us-east-2a","us-east-2b","us-east-2c"]
}

variable "cidr_subnets"{
    type = "list"
    default = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
}