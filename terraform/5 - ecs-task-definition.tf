# Creating the ECS task definition


resource "aws_ecs_task_definition" "main" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_definition_cpu_allocation    #.25 vCPU
  memory                   = var.ecs_task_definition_memory_allocation # 0.5 GB
  task_role_arn            = aws_iam_role.Execution_Role.arn
  execution_role_arn       = aws_iam_role.Execution_Role.arn
  container_definitions = jsonencode([{
    name      = "${var.ecs_container_name}"
    image     = "${var.ecr_container_image_url}"
    cpu       = "${var.ecs_task_definition_cpu_allocation}"    #.25 vCPU
    memory    = "${var.ecs_task_definition_memory_allocation}" # 0.5 GB
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

