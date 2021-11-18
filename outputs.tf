output "load_balancer_ip" {
  value = aws_lb.galera-lb.dns_name
}