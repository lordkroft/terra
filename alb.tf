data "aws_subnet_ids" "public" {
   vpc_id = module.aws_vpc.galera-vpc.id.vpc_id
   filter {
    name   = "tag:Name"
    values = ["public_subnet*"]
  }
}

resource "aws_lb" "galera-alb" {
  name            = "galera-alb"
  subnets         = data.aws_subnet_ids.public_subnet.ids
  load_balancer_type = "application"
  security_groups = [aws_security_group.galera-alb-sg.id]
  internal           = false
}


resource "aws_lb_target_group" "galera-tg-http" {
  name        = "galera-tg-http"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = module.aws_vpc.galera-vpc.id.vpc_id
  target_type = "ip"
  health_check {
    path                = "/index"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    matcher             = "200"
  }
}


resource "aws_lb_listener" "galera-http-listener" {
  load_balancer_arn = aws_lb.galera-lb.id
  port              = "8080"
  protocol          = "HTTP"
  depends_on        = [aws_lb_target_group.galera-tg-http]

  default_action {
    target_group_arn = aws_lb_target_group.galera-tg-http.arn
    type             = "forward"
  }
}