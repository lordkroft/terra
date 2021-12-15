output "load_balancer_ip" {
  value = aws_lb.galera_alb.dns_name
}