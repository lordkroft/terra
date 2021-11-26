resource "aws_ecs_cluster" "my_ecs_app" {
  name = "my_ecs_app"
  tags = {
    Name        = "my_ecs_app"
  }
}

resource "aws_cloudwatch_log_group" "my_ecs_app-log-group" {
  name = "my_ecs_app-logs"

  tags = {
    Application = "App"
  }
}

resource "aws_cloudwatch_log_stream" "my_ecs_app-log-stream" {
  name           = "my_ecs_app-log-stream"
  log_group_name = aws_cloudwatch_log_group.my_ecs_app-log-group.name
}

resource "aws_ecs_task_definition" "my_ecs_app-task-def" {
  family = "my_ecs_app-task"

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
          "awslogs-group": "${aws_cloudwatch_log_group.my_ecs_app-log-group.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${aws_cloudwatch_log_stream.my_ecs_app-log-stream.name}"
        }
      },
      "portMappings": [
        {
          "containerPort": 8080,
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
          "awslogs-group": "${aws_cloudwatch_log_group.my_ecs_app-log-group.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${aws_cloudwatch_log_stream.my_ecs_app-log-stream.name}"
        }
      },
      "networkMode": "bridge"
    }
  ]
  DEFINITION

  requires_compatibilities = ["EC2"]
  tags = {
    Name        = "front-ecs-task-definition"
  }
}

resource "aws_ecs_service" "service" {
  name            = "service"
  cluster         = aws_ecs_cluster.my_ecs_app.id
  task_definition = aws_ecs_task_definition.my_ecs_app-task-def.arn
  desired_count   = "${var.desired_count}"
  deployment_maximum_percent = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  health_check_grace_period_seconds  = "${var.health_check_grace_period_seconds}"

  
  load_balancer {
    target_group_arn = aws_lb_target_group.galera-tg-http.arn
    container_name   = "nginx-front"
    container_port   = 8080
  }
  deployment_controller {
      type = "ECS"
  }
}

