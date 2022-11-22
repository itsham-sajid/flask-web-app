variable "env_tag" {
  description = "Prod Environment tag"
  type        = string
  default     = "Prod"
}

variable "application_tag" {
  description = "Application tag"
  type        = string
  default     = "Movie App"
}

variable "aws_alb_name" {
  description = "Application Load Balancer Name"
  type        = string
  default     = "web-app-alb"

}

variable "aws_alb_target_group_name" {
  description = "Application Load Balancer Target Group Name"
  type        = string
  default     = "alb-target-group"

}


variable "ecs_container_name" {
  description = "Container name for ECS task definition"
  type        = string

}

variable "ecr_container_image_url" {
  description = "Amazon ECR container image url"
  type        = string
}


variable "ecs_task_definition_cpu_allocation" {
  description = "Amazon ECR container image url"
  type        = number
  default     = 256
}

variable "ecs_task_definition_memory_allocation" {
  description = "Amazon ECR container image url"
  type        = number
  default     = 512
}

variable "ecs_cluster_name" {
  description = "Amazon ECS Cluster Name"
  type        = string
  default     = "app-cluster"

}

variable "aws_ecs_service_name" {
  description = "Amazon ECS Service Name"
  type        = string
  default     = "app-service"

}

variable "aws_ecs_service_desired_count" {
  description = "Amazon ECS Service Name"
  type        = number
  default     = 2

}



