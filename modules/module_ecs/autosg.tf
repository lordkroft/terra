resource "aws_autoscaling_group" "cluster" {
  name                 = "auto_scaling_group"
  max_size             = 4
  min_size             = 1
  desired_capacity     = 1
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.launch_config.name
  vpc_zone_identifier  = var.private_subnets #module.module_networking.private_subnets_ids

  tag {
    key                 = "Name"
    value               = "ecs_instance"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "ecs_asg" {
  name                      = "ecs_asg"
  vpc_id                    = var.vpc_id #module.module_networking.vpc_id

  ingress {
    from_port               = 0
    to_port                 = 0 
    protocol                = "tcp"
  #  security_groups         = [aws_security_group.load_balancer.id]
  }


  ingress {
    from_port               = 22
    to_port                 = 22
    protocol                = "tcp"
  #  security_groups         = [aws_security_group.bastion_sg.id]
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
  image_id      = "ami-086e001f1a73d208c"
  instance_type = "t2.micro"
  security_groups             = [aws_security_group.ecs_asg.id]
  iam_instance_profile        = aws_iam_instance_profile.ecs_ec2.name
  associate_public_ip_address = false
  key_name = "app-demo-key"
  root_block_device {
    volume_size = 30
    volume_type = "gp2"
    delete_on_termination = true
  }
  user_data = <<EOF
#!/bin/bash
echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;
echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config;
EOF


 lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
    name = "scale_up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.cluster.name}"
}

resource "aws_autoscaling_policy" "scale_down" {
    name = "scale_down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.cluster.name}"
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
    alarm_name = "high_util_memory"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "AWS/EC2"
    period = "300"
    statistic = "Average"
    threshold = "85"
    alarm_description = "Memory utilization >85%"
    alarm_actions = [
        "${aws_autoscaling_policy.scale_up.arn}",
        "${aws_appautoscaling_policy.up.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.cluster.name
    }
}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
    alarm_name = "low_util_memory"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "AWS/EC2"
    period = "300"
    statistic = "Average"
    threshold = "50"
    alarm_description = "Memory utilization is normal"
    alarm_actions = [
        "${aws_autoscaling_policy.scale_down.arn}",
        "${aws_appautoscaling_policy.down.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.cluster.name
    }
}

resource "aws_appautoscaling_target" "ecs_app_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "up" {
    name = "${var.cluster_name}_scale_up" #"${aws_ecs_service.service.name}_scale_up"
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
    name = "${var.cluster_name}_scale_down" #"${aws_ecs_service.service.name}_scale_down"
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
