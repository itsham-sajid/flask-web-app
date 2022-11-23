# Creating ECS Service 

resource "aws_ecs_service" "main" {
  name                = var.aws_ecs_service_name
  cluster             = aws_ecs_cluster.main.id
  task_definition     = aws_ecs_task_definition.main.id
  desired_count       = var.aws_ecs_service_desired_count
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.container-sg.id]
    subnets          = [aws_subnet.public-eu-west-2a.id, aws_subnet.public-eu-west-2b.id, aws_subnet.public-eu-west-2c.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.id
    container_name   = var.ecs_container_name
    container_port   = "80"
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    name = "${var.application_tag} - ECS Service"
    env  = var.env_tag
  }

}
