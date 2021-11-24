resource "aws_iam_instance_profile" "ecs_ec2" {
  name = "ecs_profile"
  role = aws_iam_role.ecsIR.name
}

resource "aws_iam_role" "ecsIR" {
  name = "ecsIR"
  assume_role_policy =  file("role-policy/ec2-role.json")
  
  tags = {
    Name = "ecs_iam"
  }
}

resource "aws_iam_role_policy" "amazonEC2ContainerServiceforEC2Role" {
  name   = "ecs_instance_role_policy"
  policy = file("role-policy/ecs-instance-role-policy.json")
  role       = aws_iam_role.ecsIR.name
  }

