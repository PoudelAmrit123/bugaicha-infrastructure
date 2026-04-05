variable "ami_id" {
  type        = string
  description = "AMI ID for the instance"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
  default     = "t3.micro"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to launch the instance into"
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Whether to assign a public IP"
  default     = false
}

variable "key_name" {
  type        = string
  description = "Name of the SSH keypair"
  default     = null
}



variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs"
  default     = []
}

variable "user_data" {
  type        = string
  description = "User data script"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply"
  default     = {}
}

variable "name" {
  type        = string
  description = "Name tag for the instance"
}

variable "source_dest_check" {
  type        = bool
  description = "Controls whether source/destination checking is enabled on the instance"
  default     = true
}

variable "vpc_id" {
  type = string


}



############

variable "iam_policy_arns" {
  type    = list(string)
  default = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
}
