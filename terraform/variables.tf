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

variable "ecs_container_name" {
  description = "Container name for ECS task definition"
  type        = string
  default     = "movie-app"
}