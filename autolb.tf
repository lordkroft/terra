data "aws_subnet_ids" "public" {
   vpc_id = module.dev-vpc.vpc_id
   filter {
    name   = "tag:Name"
    values = ["aws_subnet_public*"]
  }
}


resource "aws_lb" "galera-alb" {
  name            = "galera-alb"
  subnets         = data.aws_subnet_ids.public.ids
  load_balancer_type = "application"
  security_groups = [aws_security_group.galera-alb-sg.id]
  internal           = false
}


resource "aws_lb_target_group" "galera-tg-http" {
  name        = "galera-tg-http"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = module.dev-vpc.vpc_id
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
  load_balancer_arn = aws_lb.galera-alb.id
  port              = "8080"
  protocol          = "HTTP"
  depends_on        = [aws_lb_target_group.galera-tg-http]

  default_action {
    target_group_arn = aws_lb_target_group.galera-tg-http.arn
    type             = "forward"
  }
}

resource "aws_security_group" "load-balancer" {
  name        = "load_balancer_security_group"
  description = "Controls access to the ALB"
  vpc_id      = module.dev-vpc.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
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