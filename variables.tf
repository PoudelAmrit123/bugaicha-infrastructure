variable "vpc_cidr" {
  description = "the cidr for the vpc"
  type        = string

}

variable "destination_cidr_block" {
  description = "destination cidr block"
  type        = string

}


variable "public_subnet" {
  description = "Public subnets with CIDR and availability zone"
  type = list(object({
    cidr              = string
    availability_zone = string
  }))

}

variable "private_subnet" {
  description = "Private subnets with CIDR and availability zone"
  type = list(object({
    cidr              = string
    availability_zone = string
  }))
}

variable "vpc_project" {
  description = "vpc project name"
  type        = string

}

variable "enable_nat_gateway" {
  type = bool

}

variable "has_private_subnet" {
  type = bool

}

variable "has_public_subnet" {
  type = bool

}

variable "enable_igw" {
  type = bool

}

variable "enable_nat_instance" {
  type = bool

}

# variable "lb_listeners" {
#   description = "List of load balancer listeners"
#   type = list(object({
#     port            = number
#     protocol        = string
#     ssl_policy      = optional(string)
#     certificate_arn = optional(string)
#     default_actions = list(object({
#       type              = string
#       target_group_name = optional(string)
#       order             = optional(number)
#       redirect = optional(object({
#         port        = optional(string, "443")
#         protocol    = optional(string, "HTTPS")
#         status_code = optional(string, "HTTP_301")
#       }))
#       fixed_response = optional(object({
#         content_type = optional(string, "text/plain")
#         message_body = optional(string, "Default response")
#         status_code  = optional(string, "404")
#       }))
#     }))
#   }))
#   default = []
# }
# variable "lb_listener_rules" {
#   description = "List of listener rules for the load balancer"
#   type = list(object({
#     listener_port     = number
#     priority          = number
#     target_group_name = string
#     action_type       = string
#     conditions = list(object({
#       host_values = optional(list(string))
#       path_values = optional(list(string))
#     }))
#   }))
#   default = []
# }
# variable "lb_target_groups" {
#   description = "List of target groups for the load balancer"
#   type = list(object({
#     name              = string
#     target_group_port = number
#     protocol          = string

#     target_type = optional(string, "ip")

#   }))
#   default = []
# }

# ##RDS
# variable "rds_engine" {
#   type = string

# }

# variable "major_engine_version" {
#   type = string
# }

# variable "parameter_name" {
#   type = string
# }

# variable "parameter_family" {
#   type = string
# }

# variable "db_option" {
#   type = map(object({
#     option_name = string
#     port        = optional(number)
#     version     = optional(string)
#     option_settings = optional(list(object({
#       name  = string
#       value = string
#     })))
#   }))


#   default = {}

# }

# variable "parameters" {
#   type = map(string)

# }

# variable "mutli_parameters" {
#   type = map(string)

# }

# variable "multi_az_family" {
#   type = string

# }
# variable "db_instance_config" {
#   description = "Map of RDS instance configurations"
#   type = map(object({
#     engine                = string
#     engine_version        = string
#     instance_class        = string
#     allocated_storage     = number
#     max_allocated_storage = number
#     storage_encrypted     = bool
#     kms_key_id            = string

#     username = string
#     password = string
#     db_name  = string
#     port     = number

#     multi_az                            = bool
#     publicly_accessible                 = bool
#     iam_database_authentication_enabled = bool

#     enable_auto_minor_version_upgrade = bool
#     deletion_protection               = bool
#     skip_final_snapshot               = bool
#     monitoring_interval               = number

#     performance_insights_enabled    = bool
#     performance_insights_kms_key_id = string

#     enable_cloudwatch_logs_exports = bool
#     cloudwatch_log_types           = list(string)
#   }))
# }





# ## S3 bucket policy (For Refrence only as it is optional and keeping it will ask for the value for input)

# # variable "bucket_policy_input" {
# #   description = "S3 bucket policy for S3 module"
# #   type = object({
# #     bucket_arns = list(string)
# #     statement   = list(object({
# #       Effect    = string
# #       Principal = any
# #       Action    = any
# #     }))
# #   })
# #   default = {
# #     bucket_arns = ["arn:aws:s3:::s3-module-lf"]
# #     statement = [
# #       {
# #         Effect    = "Allow"
# #         Principal = "*"
# #         Action    = "s3:GetObject"
# #       }
# #     ]
# #   }


# # }




# ### Cloudfront distribution


# # variable "cert_domain_name" {
# #   description = "certificate name for the cloudfront distribution"
# #   type = string 


# # }


# # variable "s3_domain_name" {
# #   type = string

# # }


# ### WAF

# variable "rules" {
#   description = "managed rule groups to include in Web ACL"
#   type = list(object({
#     name              = string
#     priority          = number
#     action            = string
#     managed_rule_name = string
#     vendor_name       = string
#   }))


# }

# variable "rule_group_rules" {
#   description = "custom rules inside the rule group"
#   type = list(object({
#     name               = string
#     priority           = number
#     action             = string
#     search_string      = optional(string)
#     rate_limit         = optional(number)
#     aggregate_key_type = optional(string)
#   }))

# }
