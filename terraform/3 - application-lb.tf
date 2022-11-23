# Creating Application Load Balancer

resource "aws_lb" "main" {
  name               = var.aws_alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public-eu-west-2a.id, aws_subnet.public-eu-west-2b.id, aws_subnet.public-eu-west-2c.id]

  enable_deletion_protection = false

  tags = {
    name = "${var.application_tag} - Application Load Balancer"
    env  = var.env_tag
  }

}

# Creating Application Load Balancer Target Group

resource "aws_alb_target_group" "main" {
  name        = var.aws_alb_target_group_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.web-app.id
  target_type = "ip"

  tags = {
    name = "${var.application_tag} - ALB Target Group A"
    env  = var.env_tag
  }


}


# Creating Application Load Balancer Listener

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.main.id
  }

  tags = {
    name = "${var.application_tag} - ALB Listener"
    env  = var.env_tag
  }

}

