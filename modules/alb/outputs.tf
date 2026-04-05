output "lb_target_group_arns" {
  value = { for k, tg in aws_lb_target_group.lb_target_group : k => tg.arn }
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.alb.dns_name
}