output "load_balancer_ip" {
  value = aws_lb.galera-alb.dns_name
}