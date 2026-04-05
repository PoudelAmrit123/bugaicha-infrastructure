variable "ecs_cluster_name" {
  description = "ecs cluster name"
  type        = string

}

variable "ebs_volume_size" {
  type    = number
  default = 30

}

variable "launch_type" {
  type    = string
  default = "EC2"

}

variable "vpc_id" {
  type = string

}



variable "instance_type" {
  default = "t2.micro"
  type    = string

}

variable "enable_ip_address" {
  default     = true
  description = "ip address in ecs launch template "

}

variable "subnet_id" {
  type = list(string)


}



variable "tags" {
  type = map(string)

  default = {
    Environment = "dev"
    Project     = "Demo Project"
  }

}



variable "services" {
  type = map(object({
    ecs_service_name             = string
    ecs_desiredCount             = number
    launch_type                  = string
    enable_alb                   = bool
    enable_public_ip_ecs_service = bool
    ecsService_subnets           = list(string)
    container_name               = string
    container_port               = number


    service_connect_configuration = optional(object({
      services = list(object({
        port_name      = string
        discovery_name = string
        client_alias = optional(list(object({
          port = number
        })), [])
      }))
    }), null)
  }))
}

variable "task" {

  type = map(object({
    containerPort = number
    family_name   = string
    launch_type   = string
    cpu           = string
    memory        = string
    network_mode  = string
    image         = string
    hostPort      = number

    portMappings = optional(list(object({
      containerPort = number
      hostPort      = number
      name          = string
    })), [])

    environment = optional(list(object({
      name  = string
      value = string
    })), [])

    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })), [])


  }))


}
variable "target_group_arns" {
  description = "Map of target group ARNs from ALB module"
  type        = map(string)
  default     = {}
}

variable "projectName" {
  type    = string
  default = "ecsService"

}

variable "environment" {
  type    = string
  default = "dev"

}
variable "force_delete" {
  type    = bool
  default = true

}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 3

}

variable "asg_min_size" {
  type    = number
  default = 1
}
variable "health_check_grace_period" {
  default = 300
  type    = number

}

variable "health_check_type" {
  type    = string
  default = "EC2"

}

variable "network_mode" {

  type    = string
  default = "awsvpc"

}

variable "api_autoscaling_enabled" {
  description = "Enable ECS service autoscaling for API service only"
  type        = bool
  default     = false
}

variable "api_service_key" {
  description = "Service key in var.services map that should autoscale"
  type        = string
  default     = "api"
}

variable "api_autoscaling_min_capacity" {
  description = "Minimum task count for API autoscaling"
  type        = number
  default     = 1
}

variable "api_autoscaling_max_capacity" {
  description = "Maximum task count for API autoscaling"
  type        = number
  default     = 6
}

variable "api_target_cpu_utilization" {
  description = "Target average CPU utilization (%) for API autoscaling"
  type        = number
  default     = 65
}

variable "api_target_memory_utilization" {
  description = "Target average memory utilization (%) for API autoscaling"
  type        = number
  default     = 75
}

variable "api_scale_in_cooldown" {
  description = "Scale-in cooldown in seconds for API autoscaling"
  type        = number
  default     = 120
}

variable "api_scale_out_cooldown" {
  description = "Scale-out cooldown in seconds for API autoscaling"
  type        = number
  default     = 60
}
