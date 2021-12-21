resource "aws_iam_instance_profile" "ecs_ec2" {
  name = "ecs_profile"
  role = aws_iam_role.ecsIR.name
}

resource "aws_iam_role" "ecsIR" {
  name = "ecsIR"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "ecs_iam"
  }
}

resource "aws_iam_role_policy" "amazonEC2ContainerServiceforEC2Role" {
  name   = "ecs_role_policy"
  role       = aws_iam_role.ecsIR.name

  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:UpdateContainerInstancesState",
                "ecs:Submit*",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": "*"
        
        },
    {
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
        ],
        "Resource": [
            "arn:aws:logs:*:*:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:TagUser",
                "iam:TagRole",
                "iam:UntagUser",
                "iam:UntagRole"
            ],
            "Resource": [
                
                "arn:aws:iam::413752907951:role/ecsIR"
            ]
        }
    ]
}
EOF
}


