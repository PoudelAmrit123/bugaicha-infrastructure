
## the ALB target type either IP or Instance.
variable "alb_tg_type" {
  default = "ip"
  type    = string

}




#################

variable "alb_name" {
  default = "ecs-alb"
  type    = string
}

variable "target_group_name" {
  default = "ecs-tg"
  type    = string

}

variable "alb_type" {
  default = "application"
  type    = string

}



variable "subnets" {
  type = list(string)


}

variable "environment" {
  default = "dev"
  type    = string

}

variable "vpc_id" {
  type = string

}

variable "protocol" {
  default = "HTTP"
  type    = string
}

variable "lb_listener_port" {
  default = 80
  type    = number

}

variable "target_group_port" {
  default = 80
  type    = number

}





variable "lb_target_groups" {

  type = list(object({
    name              = string
    target_group_port = number
    protocol          = string
    health_check = optional(object({
      path                = optional(string)
      protocol            = optional(string)
      matcher             = optional(string)
      interval            = optional(number)
      timeout             = optional(number)
      healthy_threshold   = optional(number)
      unhealthy_threshold = optional(number)
    }))

  }))
  default = []
}


variable "lb_listeners" {

  type = list(object({
    port            = number
    protocol        = string
    ssl_policy      = optional(string)
    certificate_arn = optional(string)

    default_actions = list(object({
      type             = string
      target_group_key = optional(string)
      order            = optional(number)
      redirect = optional(object({
        port        = optional(string, "443")
        protocol    = optional(string, "HTTPS")
        status_code = optional(string, "HTTP_301")
      }))
      fixed_response = optional(object({
        content_type = optional(string, "text/plain")
        message_body = optional(string, "Default response")
        status_code  = optional(string, "404")
      }))
    }))
  }))
  default = []
}

variable "lb_listener_rules" {

  type = list(object({
    listener_port     = number
    priority          = number
    target_group_name = string
    action_type       = string
    conditions = list(object({
      host_values = optional(list(string))
      path_values = optional(list(string))
    }))
  }))
  default = []
}
