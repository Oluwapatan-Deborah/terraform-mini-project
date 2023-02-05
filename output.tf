output "elb_load_balancer_dns_name" {
  value = aws_lb.miniproject-load-balancer.dns_name
}

output "elb_target_group_arn" {
  value = aws_lb_target_group.miniproject-target-group.arn
}

output "elastic_load_balancer_zone_id" {
  value = aws_lb.miniproject-load-balancer.zone_id
}
