resource "aws_ecs_cluster" "my_ecs_app" {
  name = var.cluster_name
  tags = {
    Name        = "my_ecs_app"
  }
}

resource "aws_cloudwatch_log_group" "my_ecs_app_log_group" {
  name = "my_ecs_app_log_group"

  tags = {
    Application = "App"
  }
}

resource "aws_cloudwatch_log_stream" "my_ecs_app_log_stream" {
  name           = "my_ecs_app_log_stream"
  log_group_name = aws_cloudwatch_log_group.my_ecs_app_log_group.name
}

resource "aws_ecs_task_definition" "my_ecs_app_task_def" {
  family = "my_ecs_app_task"

  container_definitions = <<DEFINITION
  [
    {
      "name": "nginx-front",
      "image": "${var.container_image_front}:latest",
      "essential": true,
      "memory": 128,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.my_ecs_app_log_group.id}",
          "awslogs-region": "us-east-2",
          "awslogs-create-group": "true",
          "awslogs-stream-prefix": "${aws_cloudwatch_log_stream.my_ecs_app_log_stream.name}"
        }
      },
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 0
        }
      ],
      "networkMode": "bridge",
      "links": ["flask"]
    },

    {
      "name": "flask",
      "image": "${var.container_image_back}:latest",
      "essential": true,
      "memory": 128,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.my_ecs_app_log_group.id}",
          "awslogs-region": "us-east-2",
          "awslogs-create-group": "true",
          "awslogs-stream-prefix": "${aws_cloudwatch_log_stream.my_ecs_app_log_stream.name}"
        }
      },
      "networkMode": "bridge"
    }
  ]
  DEFINITION

  requires_compatibilities = ["EC2"]
  tags = {
    Name        = "front_ecs_task_definition"
  }
}

resource "aws_ecs_service" "service" {
  name            = "service"
  cluster         = var.cluster_name #aws_ecs_cluster.my_ecs_app.id
  task_definition = aws_ecs_task_definition.my_ecs_app_task_def.arn
  desired_count   = var.desired_count
  deployment_maximum_percent = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  
  load_balancer {
    target_group_arn = aws_lb_target_group.galera_tg_http.arn
    container_name   = "nginx-front"
    container_port   = 80
  }
  deployment_controller {
      type = "ECS"
  }
}

