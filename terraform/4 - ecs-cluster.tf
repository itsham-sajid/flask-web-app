# Create an ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name

  tags = {
    name = "${var.application_tag} - ECS Cluster"
    env  = var.env_tag
  }


}

# Required roles for the ECS cluster task definition 

data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    sid = "EcsTaskPolicy"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]

    resources = [
      "*" # you could limit this to only the ECR repo you want
    ]
  }
  statement {

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = [
      "*"
    ]
  }

  statement {

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*"
    ]
  }

}

resource "aws_iam_role" "Execution_Role" {
  name               = "ecsExecution-1"
  assume_role_policy = data.aws_iam_policy_document.role_policy.json

  inline_policy {
    name   = "EcsTaskExecutionPolicy"
    policy = data.aws_iam_policy_document.ecs_task_policy.json
  }


}


data "aws_iam_policy_document" "role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
