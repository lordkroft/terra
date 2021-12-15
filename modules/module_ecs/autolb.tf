resource "aws_lb" "galera_alb" {
  name        = "galera-alb"
  subnets         = var.public_subnets #module.module_networking.public_subnets_ids
  load_balancer_type = "application"
  security_groups = [aws_security_group.load_balancer.id]
  internal           = false
  
}


resource "aws_lb_target_group" "galera_tg_http" {
  name        = "galera-tg-http"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id #module.module_networking.vpc_id
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


resource "aws_lb_listener" "galera_http_listener" {
  load_balancer_arn = aws_lb.galera_alb.id
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_lb_target_group.galera_tg_http]

  default_action {
    target_group_arn = aws_lb_target_group.galera_tg_http.arn
    type             = "forward"
  }
}

resource "aws_security_group" "load_balancer" {
  name        = "load_balancer_security_group"
  description = "Controls access to the ALB"
  vpc_id      = var.vpc_id #module.module_networking.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
  }