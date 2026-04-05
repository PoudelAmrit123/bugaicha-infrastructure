resource "aws_security_group" "alb_sg" {
  name        = "nginx-alb-sg-${var.environment}"
  description = "Allow HTTP from anywhere"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}



resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = var.alb_type
  subnets            = var.subnets
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "lb_target_group" {
  for_each    = { for tg in var.lb_target_groups : tg.name => tg }
  name        = "${var.target_group_name}-${each.key}-${var.environment}"
  port        = each.value.target_group_port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = var.alb_tg_type

  dynamic "health_check" {
    for_each = try(each.value.health_check, null) != null ? [1] : []
    content {
      path                = try(each.value.health_check.path, "/")
      protocol            = try(each.value.health_check.protocol, each.value.protocol)
      matcher             = try(each.value.health_check.matcher, "200")
      timeout             = coalesce(try(each.value.health_check.timeout, null), 4)
      interval            = max(coalesce(try(each.value.health_check.interval, null), 15), coalesce(try(each.value.health_check.timeout, null), 4) + 1)
      healthy_threshold   = try(each.value.health_check.healthy_threshold, 2)
      unhealthy_threshold = try(each.value.health_check.unhealthy_threshold, 3)
    }
  }



}






resource "aws_lb_listener" "lb_listener" {
  for_each = { for listener in var.lb_listeners : listener.port => listener }

  load_balancer_arn = aws_lb.alb.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = lookup(each.value, "ssl_policy", null)
  certificate_arn   = lookup(each.value, "certificate_arn", null)

  dynamic "default_action" {

    for_each = each.value.default_actions
    iterator = action
    content {
      type  = action.value.type
      order = lookup(action.value, "order", null)


      ## Should be added if only the frontend need to be exposed ( using the service Connect in that case)

      target_group_arn = aws_lb_target_group.lb_target_group[action.value.target_group_key].arn




      dynamic "redirect" {
        for_each = lookup(action.value, "redirect", null) != null ? [action.value.redirect] : []
        content {
          port        = lookup(redirect.value, "port", "443")
          protocol    = lookup(redirect.value, "protocol", "HTTPS")
          status_code = lookup(redirect.value, "status_code", "HTTP_301")
        }
      }

      dynamic "fixed_response" {
        for_each = lookup(action.value, "fixed_response", null) != null ? [action.value.fixed_response] : []
        content {
          content_type = lookup(fixed_response.value, "content_type", "text/plain")
          message_body = lookup(fixed_response.value, "message_body", "Default response")
          status_code  = lookup(fixed_response.value, "status_code", "404")
        }
      }
    }
  }
}


resource "aws_lb_listener_rule" "lb_listener_rule" {
  for_each     = var.lb_listener_rules != null ? { for rule in var.lb_listener_rules : rule.priority => rule } : {}
  listener_arn = aws_lb_listener.lb_listener[each.value.listener_port].arn
  priority     = each.value.priority

  action {
    type             = each.value.action_type
    target_group_arn = aws_lb_target_group.lb_target_group[each.value.target_group_name].arn
  }




  dynamic "condition" {
    for_each = lookup(each.value, "conditions", [])
    iterator = condition

    content {
      dynamic "path_pattern" {
        for_each = (
          try(length(condition.value.path_values) > 0, false)
        ) ? [condition.value.path_values] : []
        content {
          values = path_pattern.value
        }
      }

      dynamic "host_header" {
        for_each = (
          try(length(condition.value.host_values) > 0, false)
        ) ? [condition.value.host_values] : []
        content {
          values = host_header.value
        }
      }
    }
  }

  depends_on = [
    aws_lb_listener.lb_listener,
    aws_lb_target_group.lb_target_group
  ]
}
