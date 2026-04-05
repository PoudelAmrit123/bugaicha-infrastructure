variable "vpc_name" {
  description = "VPC name"
  type        = string

}
variable "vpc_project" {
  description = "vpc project name"
  type        = string
}


variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}


variable "public_subnet" {
  description = "the public subnet for the vpc"
  type = list(object({
    cidr              = string
    availability_zone = string
  }))

}

variable "private_subnet" {
  description = "the private subnet for the VPC"
  type = list(object({
    cidr              = string
    availability_zone = string
  }))

}

# variable "public_availability_zone" {
#     description = "availabiltiy zone for the public subnet"
#     type = list(string)

# }



variable "enable_igw" {
  description = "enable the igw or not "
  type        = bool
  default     = true

}

variable "has_public_subnet" {
  description = "creating the route table or not"
  type        = bool
  default     = true

}

variable "destination_cidr_block" {
  description = "destination cidr block"
  type        = string
  default     = "0.0.0.0/0"

}

variable "enable_nat_gateway" {
  description = "enable the nat gateway or not "
  type        = bool

}

variable "has_private_subnet" {
  description = "doesnot have the private subnet"
  type        = bool

}

variable "aws_instance_ami" {
  type    = string
  default = "ami-024cf76afbc833688"


}

variable "enable_nat_instance" {
  type = bool

}

variable "nat_instance_count" {
  type    = number
  default = 1

}


variable "aws_cloudwatch_log_group" {
  type    = string
  default = "/aws/vpc-flow-logs/amrit_vpc"

}