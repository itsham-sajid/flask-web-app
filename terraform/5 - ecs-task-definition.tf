# Creating the ECS task definition


resource "aws_ecs_task_definition" "main" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256 #.25 vCPU
  memory                   = 512 # 0.5 GB
  task_role_arn            = aws_iam_role.Execution_Role.arn
  execution_role_arn       = aws_iam_role.Execution_Role.arn
  container_definitions = jsonencode([{
    name      = "movie-app"
    image     = "035736936356.dkr.ecr.eu-west-2.amazonaws.com/flask-web-app:web-app-latest"
    cpu       = 256 #.25 vCPU
    memory    = 512 # 0.5 GB
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
      }
    ]
    }
  ])

  tags = {
    name = "${var.application_tag} - ECS Fargate Task"
    env  = var.env_tag
  }
}

