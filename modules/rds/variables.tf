variable "subnet_ids" {
  description = "subnet id for the rds security group"
  type        = list(string)
}


variable "tags" {
  type = map(string)
  default = {
    Project = "rds-moudle"
  }

}

variable "parameters" {

  type = map(string)
}

variable "parameter_name" {
  type = string

}
variable "create_db_subnet_group" {
  type    = bool
  default = true

}

variable "parameter_family" {
  type = string
}


# variable "enable_create_before_lifecycle_destroy" {
#   type = bool 
#   default = true
# }

variable "create_option_group" {
  type    = bool
  default = false
}


variable "engine" {
  type = string


}
variable "major_engine_version" {
  type = string

}

variable "db_option" {

  type = map(object({
    option_name = string
    port        = optional(number)
    version     = optional(string)
  }))

}


variable "db_identifier" {
  type    = string
  default = "demo-app-ap"

}

variable "create_security_group" {
  type    = bool
  default = true

}

variable "security_group_name" {
  type    = string
  default = "rds-sg-ap"

}

variable "vpc_id" {
  type = string

}


variable "create_monitoring_role" {
  type    = bool
  default = false
}

variable "db_instance_config" {
  type = map(object({

    engine                = string
    engine_version        = string
    instance_class        = string
    allocated_storage     = number
    max_allocated_storage = number
    storage_encrypted     = bool
    kms_key_id            = optional(string)


    username = string
    password = string
    db_name  = string
    port     = number



    multi_az                            = bool
    publicly_accessible                 = bool
    iam_database_authentication_enabled = bool



    enable_auto_minor_version_upgrade = bool
    deletion_protection               = bool
    skip_final_snapshot               = bool
    monitoring_interval               = optional(number)


    performance_insights_enabled    = optional(bool)
    performance_insights_kms_key_id = optional(string)


    enable_cloudwatch_logs_exports = optional(bool)
    cloudwatch_log_types           = optional(list(string))



  }))

}


variable "multi_db_instance_config" {
  type = map(object({


    name_prefix = string


    engine            = string
    engine_version    = string
    instance_class    = string
    allocated_storage = number
    # max_allocated_storage               = number
    storage_encrypted = bool
    kms_key_id        = optional(string)


    master_username = string
    master_password = string
    database_name   = string
    port            = number




    publicly_accessible                 = bool
    iam_database_authentication_enabled = bool
    storage_type                        = string




    deletion_protection = bool
    skip_final_snapshot = bool
    monitoring_interval = optional(number)


    performance_insights_enabled    = optional(bool)
    performance_insights_kms_key_id = optional(string)


    enable_cloudwatch_logs_exports = optional(bool)
    cloudwatch_log_types           = optional(list(string))

    apply_immediately = bool



  }))

  default = {
    primary = {
      name_prefix       = "demo-db"
      engine            = "postgres"
      engine_version    = "17.4"
      instance_class    = "db.m5d.large"
      allocated_storage = 20
      storage_encrypted = false
      kms_key_id        = null
      storage_type      = "gp3"

      master_username = "amrit"
      master_password = "StrongPassword123!"
      database_name   = "demoapp"
      port            = 3306

      publicly_accessible                 = false
      iam_database_authentication_enabled = false

      deletion_protection = false
      skip_final_snapshot = false
      monitoring_interval = 0

      performance_insights_enabled    = false
      performance_insights_kms_key_id = null

      enable_cloudwatch_logs_exports = false
      cloudwatch_log_types           = []

      apply_immediately = true
    }
  }

}


## Single AZ 
variable "create_parameter_group" {
  type    = bool
  default = true

}


## Db subnet group , parameter group and option group are either created 
## if already created and want to use , the value can be passed 
variable "db_subnet_group_name" {
  type    = string
  default = null

}

variable "vpc_security_group_ids" {
  type    = list(string)
  default = []

}


variable "parameter_group_name" {
  type    = string
  default = null

}

variable "option_group_name" {
  type    = string
  default = null


}

variable "monitoring_role_arn" {
  type    = string
  default = null

}

## sg


variable "ingress_rules" {
  description = "List of ingress rules for the RDS security group"
  type = list(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
    description      = optional(string)
  }))
  default = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow MySQL access from anywhere"
    }
  ]
}

variable "egress_rules" {
  description = "List of egress rules for the RDS security group"
  type = list(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
    description      = optional(string)
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}


variable "is_multi_az" {
  description = "is the instance is multi or not "
  type        = bool
  default     = true

}

variable "enable_db_instance" {
  description = "is local"
  type        = bool
  default     = false

}

variable "name" {
  description = "name of the AZ multi value "
  type        = string
  default     = "multi-az"

}

variable "multi_az_family" {
  description = "the name of the multi az family"
  type        = string
  default     = "mysql8.0"

}

variable "mutli_parameters" {
  description = "the name of the multi paramters "
  type        = map(string)
  default = {
    max_connections = "200"
    slow_query_log  = "1"
  }

}



