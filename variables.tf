variable "regions" {
  type    = "list"
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "cidr_subnets" {
  type = "map"
  default = {
    us-east-2a = "10.0.1.0/24"
    us-east-2b = "10.0.2.0/24"
    us-east-2c = "10.0.3.0/24"
  }
}

variable "default_port" {
  default = 80
}

variable "default_protocol" {
  type = "map"
  default = {
    "80" = "TCP"
    "22" = "TCP"
  }
}