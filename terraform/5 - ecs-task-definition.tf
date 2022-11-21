# Creating the ECS task definition


resource "aws_ecs_task_definition" "main" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  task_role_arn            = aws_iam_role.Execution_Role.arn
  execution_role_arn       = aws_iam_role.Execution_Role.arn
  container_definitions = jsonencode([{
    name      = "movie-app"
    image     = "035736936356.dkr.ecr.eu-west-2.amazonaws.com/flask-web-app:web-app-latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
      }
    ]
    }
  ])
}

