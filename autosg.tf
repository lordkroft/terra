data "aws_subnet_ids" "private" {
   vpc_id = module.dev-vpc.vpc_id
   filter {
    name   = "tag:Name"
    values = ["aws_subnet_private*"]
  }
}

resource "aws_autoscaling_group" "cluster" {
  name                 = "auto_scaling_group"
  max_size             = 4
  min_size             = 1
  desired_capacity     = 1
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.launch_config.name
  vpc_zone_identifier  = data.aws_subnet_ids.private.ids

  tag {
    key                 = "Name"
    value               = "ecs_instance"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "ecs_asg" {
  name                      = "ecs_asg"
  vpc_id                    = module.dev-vpc.vpc_id

  ingress {
    from_port               = 0
    to_port                 = 5000#65535
    protocol                = "tcp"
    security_groups         = [aws_security_group.load-balancer.id]
  }


  ingress {
    from_port               = 22
    to_port                 = 22
    protocol                = "tcp"
    security_groups         = [aws_security_group.bastion.id]
  }


  egress {
    from_port               = 0
    to_port                 = 0
    protocol                = "-1"
    cidr_blocks             = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "launch_config" {
  name          = "ecs_cluster"
  image_id      = "ami-0b440d17bfb7989dc"
  instance_type = "t3.nano"
  security_groups             = [aws_security_group.ecs_asg.id]
  iam_instance_profile        = aws_iam_instance_profile.ecs_ec2.name
  associate_public_ip_address = false
  key_name = "app-demo-key.pem"
  root_block_device {
    volume_size = 30
    volume_type = "gp2"
    delete_on_termination = true
  }
  user_data = <<EOF
#!/bin/bash
echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;
echo ECS_CLUSTER=${aws_ecs_cluster.my_ecs_app.name} >> /etc/ecs/ecs.config;
EOF


 lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale-up" {
    name = "scale-up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.cluster.name}"
}

resource "aws_autoscaling_policy" "scale-down" {
    name = "scale-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.cluster.name}"
}

resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name = "high-util-memory"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "AWS/EC2"
    period = "300"
    statistic = "Average"
    threshold = "85"
    alarm_description = "Memory utilization >85%"
    alarm_actions = [
        "${aws_autoscaling_policy.scale-up.arn}",
        "${aws_appautoscaling_policy.up.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.ecs-cluster.name
    }
}

resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name = "low-util-memory"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "AWS/EC2"
    period = "300"
    statistic = "Average"
    threshold = "50"
    alarm_description = "Memory utilization is normal"
    alarm_actions = [
        "${aws_autoscaling_policy.scale-down.arn}",
        "${aws_appautoscaling_policy.down.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.cluster.name
    }
}

resource "aws_appautoscaling_target" "ecs_app_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.my_ecs_app.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "up" {
    name = "${aws_ecs_service.service.name}_scale_up"
    service_namespace  = "ecs"
    resource_id        = aws_appautoscaling_target.ecs_app_target.resource_id
    scalable_dimension = aws_appautoscaling_target.ecs_app_target.scalable_dimension   
    step_scaling_policy_configuration {
        adjustment_type = "ChangeInCapacity"
        cooldown = 60
        metric_aggregation_type = "Maximum"
        step_adjustment {
            metric_interval_lower_bound = 0
            scaling_adjustment = 2
        }
    }
    depends_on = [aws_appautoscaling_target.ecs_app_target]
}

resource "aws_appautoscaling_policy" "down" {
    name = "${aws_ecs_service.service.name}_scale_down"
    service_namespace = "ecs"
    resource_id        = aws_appautoscaling_target.ecs_app_target.resource_id
    scalable_dimension = aws_appautoscaling_target.ecs_app_target.scalable_dimension   
    step_scaling_policy_configuration {
        adjustment_type = "ChangeInCapacity"
        cooldown = 60
        metric_aggregation_type = "Maximum"
        step_adjustment {
            metric_interval_lower_bound = 0
            scaling_adjustment = -2
        }
    }
    depends_on = [aws_appautoscaling_target.ecs_app_target]
}
